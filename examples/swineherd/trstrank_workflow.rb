#!/usr/bin/env jruby

require 'rubygems'
require 'hackboxen'
require 'swineherd' ; include Swineherd
require 'swineherd/script/pig_script' ; include Swineherd::Script
require 'swineherd/script/wukong_script'
require 'gorillib/datetime/flat'

hdfs = Swineherd::FileSystem.get(:hdfs)

# Read in working config file
options = Configliere::Param.new
options.read_json hdfs.open(File.join(path_to(:env_dir), "working_config.json")).read

trstrank_tsv = File.join(path_to(:data_dir), "trstrank")
bzipd_out    = File.join(path_to(:data_dir), "trstrank_bzip")

def hdfs_exists?(target) system %Q{ hadoop fs -test -e #{target} } ; end

id = Time.now.to_flat[0..7].to_s

trstrank = Workflow.new(id) do

  #
  # Scripts needed to run trstrank workflow
  #
  templates = File.join(path_to(:hb_engine), 'templates/trstrank')
  graph_assembler      = PigScript.new(File.join(templates, 'assemble_multigraph.pig.erb'))
  degrees_calculator   = PigScript.new(File.join(templates, 'degree_distribution.pig.erb'))
  pagerank_initializer = PigScript.new(File.join(templates, 'pagerank_initialize.pig.erb'))
  pagerank_iterator    = PigScript.new(File.join(templates, 'pagerank_iterate.pig.erb'))
  followers_joiner     = PigScript.new(File.join(templates, 'join_and_scale.pig.erb'))
  followers_binner     = WukongScript.new(File.join(templates, 'trst_quotient.rb'))
  trstrank_assembler   = PigScript.new(File.join(templates, 'trstrank_assembler.pig.erb'))

  #
  # Take a_follows_b and a_atsigns_b and assemble multigraph
  #
  task :assemble_multigraph do
    graph_assembler.env['PIG_CLASSPATH'] = options[:pig][:classpath]
    graph_assembler.env['PIG_OPTS']      = options[:pig][:options].join(" ")
    graph_assembler.attributes = {
      :jars              => options[:hbase][:jars],
      :twitter_rel_table => options[:hbase][:twitter_rel_table],
      :reduce_tasks      => options[:hadoop][:reduce_tasks],
      :hbase_config      => options[:hbase][:config],
      :out               => next_output(:assemble_multigraph)
    }
    puts latest_output(:assemble_multigraph)
    puts File.read(graph_assembler.script)
    graph_assembler.run unless hdfs_exists? latest_output(:assemble_multigraph)
  end

  #
  # Use the multigraph to create initial input for pagerank
  #
  task :pagerank_initialize => [:assemble_multigraph] do
    pagerank_initializer.env['PIG_CLASSPATH'] = options[:pig][:classpath]
    pagerank_initializer.env['PIG_OPTS']      = options[:pig][:options].join(" ")
    pagerank_initializer.attributes = {
      :multigraph   => latest_output(:assemble_multigraph),
      :reduce_tasks => options[:hadoop][:reduce_tasks],
      :out          => next_output(:pagerank_initialize)
    }
    pagerank_initializer.run unless hdfs_exists? latest_output(:pagerank_initialize)
  end

  #
  # Iterate pagerank multiple times over the multigraph
  #
  task :pagerank_iterate => [:pagerank_initialize] do
    pagerank_iterator.env['PIG_CLASSPATH'] = options[:pig][:classpath]
    pagerank_iterator.env['PIG_OPTS']      = options[:pig][:options].join(" ")
    pagerank_iterator.attributes = {
      :reduce_tasks      => options[:hadoop][:reduce_tasks],
      :pagerank_damping  => options[:trstrank][:damping],
      :current_iteration => latest_output(:pagerank_initialize)
    }
    options[:trstrank][:iterations].to_i.times do
      pagerank_iterator.attributes[:next_iteration]    = next_output(:pagerank_iterate)
      pagerank_iterator.run unless hdfs_exists? latest_output(:pagerank_iterate)
      pagerank_iterator.refresh!
      pagerank_iterator.attributes[:current_iteration] = latest_output(:pagerank_iterate)
    end
  end

  #
  # Calculate the degree distribution of the multigraph
  #
  task :multigraph_degrees => [:assemble_multigraph] do
    degrees_calculator.env['PIG_CLASSPATH'] = options[:pig][:classpath]
    degrees_calculator.env['PIG_OPTS']      = options[:pig][:options].join(" ")
    degrees_calculator.attributes = {
      :reduce_tasks        => options[:hadoop][:reduce_tasks],
      :multigraph          => latest_output(:assemble_multigraph),
      :degree_distribution => next_output(:multigraph_degrees)
    }
    degrees_calculator.run unless hdfs_exists? latest_output(:multigraph_degrees)
  end

  #
  # Stream degree_distribution, multigraph, and the last_pagerank to s3 for future reference
  #
  task :store_valuable_graph_data => [:multigraph_degrees, :pagerank_iterate] do
    deg_dist_out   = File.join(options[:s3_graph_dir], options[:workflow][:id].to_s, 'degree_distribution')
    multigraph_out = File.join(options[:s3_graph_dir], options[:workflow][:id].to_s, 'multigraph')
    last_pagerank  = File.join(options[:s3_graph_dir], options[:workflow][:id].to_s, 'last_pagerank')
    hdfs.stream(latest_output(:multigraph_degrees), deg_dist_out)    unless hdfs_exists? deg_dist_out
    hdfs.stream(latest_output(:assemble_multigraph), multigraph_out) unless hdfs_exists? multigraph_out
    hdfs.stream(latest_output(:pagerank_iterate), last_pagerank)     unless hdfs_exists? last_pagerank
  end

  #
  # Scales final pagerank values to (0-10) and joins it with the followers
  # observed.
  #
  # FIXME: why doesn't multitask work here?
  #
  # multitask :join_pagerank_with_followers => [:multigraph_degrees, :pagerank_iterate] do
  task :join_pagerank_with_followers => [:store_valuable_graph_data] do
    followers_joiner.env['PIG_CLASSPATH'] = options[:pig][:classpath]
    followers_joiner.env['PIG_OPTS']      = options[:pig][:options].join(" ")
    followers_joiner.attributes = {
      :reduce_tasks        => options[:hadoop][:reduce_tasks],
      :degree_distribution => latest_output(:multigraph_degrees),
      :pagerank_output     => latest_output(:pagerank_iterate),
      :out                 => next_output(:join_pagerank_with_followers)
    }
    followers_joiner.run unless hdfs_exists? latest_output(:join_pagerank_with_followers)
  end

  #
  # Bin users by followers observed and get percentiles
  #
  task :trstquotient => [:join_pagerank_with_followers] do
    followers_binner.output << next_output(:trstquotient)
    followers_binner.input  << latest_output(:join_pagerank_with_followers)
    followers_binner.options = {
      :forank_table => File.join(templates, 'forank_table.rb'),
      :atrank_table => File.join(templates, 'atrank_table.rb')
    }
    followers_binner.run unless hdfs_exists? latest_output(:trstquotient)
  end

  #
  # Assemble all the components to form final trstrank table.
  #
  task :assemble_trstrank => [:trstquotient] do
    trstrank_assembler.env['PIG_CLASSPATH'] = options[:pig][:classpath]    
    trstrank_assembler.env['PIG_OPTS']      = options[:pig][:options].join(" ")
    trstrank_assembler.attributes = {
      :jars           => options[:hbase][:jars],
      :hbase_config   => options[:hbase][:config],
      :twuid_table    => options[:hbase][:twitter_users_table],
      :reduce_tasks   => options[:hadoop][:reduce_tasks],
      :twuid_cf       => options[:hbase][:twitter_users_cf],
      :rank_with_tq   => latest_output(:trstquotient),
      :tsv_version    => trstrank_tsv
    }
    puts File.read(trstrank_assembler.script)
    trstrank_assembler.run unless hdfs_exists? trstrank_tsv
  end

  task :package_trstrank => [:assemble_trstrank] do
    hdfs.bzip(trstrank_tsv, bzipd_out) unless hdfs_exists? bzipd_out
  end

  task :send_trstrank_to_its_final_resting_place_in_the_cloud => [:package_trstrank] do
    adorned = "trstrank_#{options[:workflow][:id]}.tsv.bz2"
    output  = File.join(options[:trstrank][:final_resting_place_in_the_cloud], adorned)
    input   = File.join(bzipd_out, "part-00000.bz2")
    cmd     = "hadoop fs -cp #{input} #{output}"
    sh cmd unless hdfs_exists?(output)
  end

end

trstrank.workdir = path_to(:rawd_dir)
trstrank.run(:send_trstrank_to_its_final_resting_place_in_the_cloud)
