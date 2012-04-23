#!/usr/bin/env ruby
require 'rubygems'
require 'swineherd' ; include Swineherd
require 'swineherd/script/pig_script' ; include Swineherd::Script
require 'swineherd/script/wukong_script'

Settings.read('./config/parse_config.yaml')
Settings.resolve!

def get_esindex month
  index = Settings['elasticsearch']['indices_mapping'][month.to_i]
  return index if index
  "tweet-#{month}"
end

hdfs = Swineherd::FileSystem.get(:hdfs)

flow = Workflow.new(Settings['workflow']['id']) do

  api_parser          = WukongScript.new(File.join(Settings['wuclan_parse_scripts'], 'parse_twitter_api_requests-v2.rb'))
  stream_parser       = WukongScript.new(File.join(Settings['wuclan_parse_scripts'], 'parse_twitter_stream_requests-v2.rb'))
  search_parser       = WukongScript.new(File.join(Settings['wuclan_parse_scripts'], 'parse_twitter_search_request.rb'))
  unsplicer           = PigScript.new(File.join(Settings['ics_data_twitter_scripts'], 'templates/unsplice_objects.pig.erb'))
  tweet_unsplicer     = PigScript.new(File.join(Settings['ics_data_twitter_scripts'], 'templates/unsplice_tweets.pig.erb'))
  tweet_rectifier     = PigScript.new(File.join(Settings['ics_data_twitter_scripts'], 'templates/rectify_twnoids.pig.erb'))
  rels_rectifier      = PigScript.new(File.join(Settings['ics_data_twitter_scripts'], 'templates/rectify_ats_into_hbase.pig.erb'))
  tweet_indexer       = PigScript.new(File.join(Settings['ics_data_twitter_scripts'], 'templates/tweet_indexer.pig.erb'))
  token_loader        = PigScript.new(File.join(Settings['ics_data_twitter_scripts'], 'templates/token_loader.pig.erb'))
  tweet_loader        = PigScript.new(File.join(Settings['ics_data_twitter_scripts'], 'templates/tweet_loader.pig.erb'))
  a_ats_b_loader      = PigScript.new(File.join(Settings['ics_data_twitter_scripts'], 'templates/a_atsigns_b_loader.pig.erb'))
  a_fos_b_loader      = PigScript.new(File.join(Settings['ics_data_twitter_scripts'], 'templates/a_follows_b_loader.pig.erb'))
  delete_tweet_loader = PigScript.new(File.join(Settings['ics_data_twitter_scripts'], 'templates/delete_tweet_loader.pig.erb'))
  geo_loader          = PigScript.new(File.join(Settings['ics_data_twitter_scripts'], 'templates/geo_loader.pig.erb'))
  screen_name_loader  = PigScript.new(File.join(Settings['ics_data_twitter_scripts'], 'templates/screen_name_loader.pig.erb'))
  search_id_loader    = PigScript.new(File.join(Settings['ics_data_twitter_scripts'], 'templates/search_id_loader.pig.erb'))
  user_id_loader      = PigScript.new(File.join(Settings['ics_data_twitter_scripts'], 'templates/twitter_user_id_loader.pig.erb'))
  profile_loader      = PigScript.new(File.join(Settings['ics_data_twitter_scripts'], 'templates/twitter_user_profile_loader.pig.erb'))
  style_loader        = PigScript.new(File.join(Settings['ics_data_twitter_scripts'], 'templates/twitter_user_style_loader.pig.erb'))

  #
  # Uses a wukong script to parse data from the normal twitter api.
  #
  task :parse_twitter_api do
    api_parser.input << File.join(Settings['ripd_s3_url'], 'com.twitter.api', Settings['api_parse_regexp'])
    api_parser.output << next_output(:parse_twitter_api)
    api_parser.run unless hdfs.exists? latest_output(:parse_twitter_api)
  end

  #
  # Uses a wukong script to parse data from the search twitter api.
  #
  task :parse_twitter_search do
    search_parser.input << File.join(Settings['ripd_s3_url'], 'com.twitter.search', Settings['search_parse_regexp'])
    search_parser.output << next_output(:parse_twitter_search)
    search_parser.run unless hdfs.exists? latest_output(:parse_twitter_search)
  end

  #
  # Uses a wukong script to parse data from the streaming twitter api.
  #
  task :parse_twitter_stream do
    stream_parser.input << File.join(Settings['ripd_s3_url'], 'com.twitter.stream', Settings['stream_parse_regexp'])
    stream_parser.output << next_output(:parse_twitter_stream)
    stream_parser.run unless hdfs.exists? latest_output(:parse_twitter_stream)
  end

 
  #
  # Reduces the (possibly) large number of input files to a more managable amount
  #
  task :reduce_files => [:parse_twitter_search, :parse_twitter_stream, :parse_twitter_api] do
    input   = [latest_output(:parse_twitter_stream), latest_output(:parse_twitter_search), latest_output(:parse_twitter_api)]
    output  = next_output(:reduce_files) 
    options = {
      :reduce_tasks     => Settings['hadoop']['file_reduce_amt'],
      :partition_fields => 3,
      :sort_fields      => 3
    }
    hdfs.dist_merge(input, output, options) unless hdfs.exists? latest_output(:reduce_files)
  end
 
  #                                                                                                                           # Uses the pig contrib UDF called 'MultiStorage' to unsplice the twitter objects into individual                            # directories keyed by object type.                                                                                         # 
  task :unsplice => [:reduce_files] do
    unsplicer.env['PIG_OPTS'] = Settings['hadoop']['pig_options']
    unsplicer.attributes = {
      :piggybank_jar => File.join(Settings['hadoop']['pig_home'], 'contrib/piggybank/java/piggybank.jar'),
      :input         => latest_output(:reduce_files),
      :out           => next_output(:unsplice)
    }
    unsplicer.run unless hdfs.exists? latest_output(:unsplice)
  end

  #
  # Joins relationships against the twitter users table. In practice this
  # means that a_atsigns_b-n will be given ids.
  #
  task :rectify_rels => [:unsplice] do
    expected_input = File.join(latest_output(:unsplice), "a_atsigns_b-n")
    next unless hdfs.exists? expected_input
    rels_rectifier.env['PIG_OPTS'] = Settings['hadoop']['pig_options']
    rels_rectifier.attributes = {
      :jars         => Settings['hbase']['jars'],
      :hbase_config => Settings['hbase']['config'],
      :ats_table    => Settings['hbase']['relationship_table'],
      :twuid_table  => Settings['hbase']['users_table'],
      :reduce_tasks => Settings['hadoop']['reduce_tasks'],
      :ats          => expected_input,
    }

    #
    # This script has no hdfs output. Instead, we fake hdfs output so that
    # the script only runs one time.
    #
    rels_rectifier.output << next_output(:rectify_rels)
    rels_rectifier.run unless hdfs.exists? latest_output(:rectify_rels)
    hdfs.mkpath(latest_output(:rectify_rels))
  end

  #
  # Rectify onto disk
  #
  task :rectify_twnoids => [:unsplice] do
    expected_input = File.join(latest_output(:unsplice), 'tweet-noid')
    next unless hdfs.exists? expected_input
    tweet_rectifier.env['PIG_OPTS'] = Settings['hadoop']['pig_options']
    tweet_rectifier.attributes = {
      :jars         => Settings['hbase']['jars'],
      :hbase_config => Settings['hbase']['config'],
      :twuid_table  => Settings['hbase']['users_table'],
      :data         => expected_input,
      :reduce_tasks => Settings['hadoop']['reduce_tasks'],
      :out          => next_output(:rectify_twnoids)
    }
    tweet_rectifier.run unless hdfs.exists? latest_output(:rectify_twnoids)
    hdfs.mkpath(latest_output(:rectify_twnoids))
  end

  task :unsplice_tweets => [:unsplice, :rectify_twnoids] do
    expected_tweet_input     = File.join(latest_output(:unsplice), 'tweet')
    expected_rectified_input = latest_output(:rectify_twnoids)
    data_input = []
    data_input << expected_tweet_input if hdfs.exists? expected_tweet_input
    data_input << expected_rectified_input if (expected_rectified_input && hdfs.exists?(expected_rectified_input))
    next unless data_input.compact.size > 0
    tweet_unsplicer.env['PIG_OPTS'] = Settings['hadoop']['pig_options']
    tweet_unsplicer.attributes = {
      :piggybank_jar => File.join(Settings['hadoop']['pig_home'], 'contrib/piggybank/java/piggybank.jar'),
      :data          => data_input.join(","),
      :out           => next_output(:unsplice_tweets)
    }
    tweet_unsplicer.output << latest_output(:unsplice_tweets)
    tweet_unsplicer.run unless hdfs.exists? latest_output(:unsplice_tweets)
  end

  task :index_tweets => [:unsplice_tweets] do
    tweet_indexer.env['PIG_OPTS'] = Settings['hadoop']['pig_options']
    input_dir = latest_output(:unsplice_tweets)
    next unless hdfs.exists? input_dir
    hdfs.entries(input_dir).each do |unspliced|
      next if unspliced =~ /_log/
      tweet_indexer.attributes = {
        :jars        => Settings['elasticsearch']['jars'],
        :data        => unspliced,
        :index_name  => get_esindex(File.basename(unspliced)),
        :obj_type    => 'tweet',
        :bulk_size   => 500,
        :config_path => Settings['elasticsearch']['config_path'],
        :plugin_path => Settings['elasticsearch']['plugin_path']
      }

      #
      # Since this script is indexing tweets directly into elasticsearch it has no
      # hdfs output. Here we simply fake hdfs output so it only runs one time.
      #
      tweet_indexer.output << next_output(:index_tweets)
      tweet_indexer.run unless hdfs.exists? latest_output(:index_tweets)
      hdfs.mkpath(latest_output(:index_tweets))
      
      tweet_indexer.refresh!
    end
  end

  task :load_tweets => [:unsplice_tweets] do
    tweet_loader.env['PIG_OPTS'] = Settings['hadoop']['pig_options']
    input_dir = latest_output(:unsplice_tweets)
    next unless hdfs.exists? input_dir
    hdfs.entries(input_dir).each do |unspliced|
      next if unspliced =~ /_log/
      tweet_loader.attributes = {
        :jars  => Settings['hbase']['jars'],
        :tweet => unspliced,
        :table => Settings['hbase']['tweet_table'],
        :hbase_config => Settings['hbase']['config']
      }

      #
      # Since this script is loading tweets directly into hbase it has no
      # hdfs output. Here we simply fake hdfs output so it only runs one time.
      #
      tweet_loader.output << next_output(:load_tweets)
      tweet_loader.run unless hdfs.exists? latest_output(:load_tweets)
      hdfs.mkpath(latest_output(:load_tweets))
      
      tweet_loader.refresh!
    end
  end

  task :load_tokens => [:unsplice] do
    token_loader.env['PIG_OPTS'] = Settings['hadoop']['pig_options']
    Settings['twitter_tokens'].each do |token|
      expected_input = File.join(latest_output(:unsplice), token)
      next unless hdfs.exists? expected_input
      token_loader.attributes = {
        :jars         => Settings['hbase']['jars'],
        :token        => expected_input,
        :table        => Settings['hbase']['token_table'],
        :hbase_config => Settings['hbase']['config']
      }

      #
      # Since this script is loading tokens directly into hbase it has no
      # hdfs output. Here we simply fake hdfs output so it only runs one time.
      #
      token_loader.output << next_output(:load_tokens)
      token_loader.run unless hdfs.exists? latest_output(:load_tokens)
      hdfs.mkpath(latest_output(:load_tokens))
      
      token_loader.refresh!
    end
  end

  task :load_a_atsigns_b => [:unsplice] do
    expected_input = File.join(latest_output(:unsplice), 'a_atsigns_b')
    next unless hdfs.exists? expected_input
    a_ats_b_loader.env['PIG_OPTS'] = Settings['hadoop']['pig_options']
    a_ats_b_loader.attributes = {
      :jars         => Settings['hbase']['jars'],
      :data         => expected_input,
      :ats_table    => Settings['hbase']['relationship_table'],
      :hbase_config => Settings['hbase']['config']      
    }

    #
    # Since this script is loading a_atsigns_b objects directly into hbase
    # it does not produce any hdfs output. Here we simply fake hdfs output
    # so it only runs one time.
    #
    a_ats_b_loader.output << next_output(:load_a_atsigns_b)
    a_ats_b_loader.run unless hdfs.exists? latest_output(:load_a_atsigns_b)
    hdfs.mkpath(latest_output(:load_a_atsigns_b))
    
  end

  task :load_a_follows_b => [:unsplice] do
    expected_input = File.join(latest_output(:unsplice), 'a_follows_b')
    next unless hdfs.exists? expected_input
    a_fos_b_loader.env['PIG_OPTS'] = Settings['hadoop']['pig_options']
    a_fos_b_loader.attributes = {
      :jars         => Settings['hbase']['jars'],
      :data         => expected_input,
      :table        => Settings['hbase']['relationship_table'],
      :hbase_config => Settings['hbase']['config']      
    }

    #
    # Since this script is loading a_follows_b objects directly into hbase
    # it does not produce any hdfs output. Here we simply fake hdfs output
    # so it only runs one time.
    #
    a_fos_b_loader.output << next_output(:load_a_follows_b)
    a_fos_b_loader.run unless hdfs.exists? latest_output(:load_a_follows_b)
    hdfs.mkpath(latest_output(:load_a_follows_b))
  end

  task :load_delete_tweets => [:unsplice] do
    expected_input = File.join(latest_output(:unsplice), 'delete_tweet')
    next unless hdfs.exists? expected_input
    delete_tweet_loader.env['PIG_OPTS'] = Settings['hadoop']['pig_options']
    delete_tweet_loader.attributes = {
      :jars         => Settings['hbase']['jars'],
      :data         => expected_input,
      :table        => Settings['hbase']['delete_tweet_table'],
      :hbase_config => Settings['hbase']['config']      
    }

    #
    # Since this script is loading delete_tweet objects directly into hbase
    # it does not produce any hdfs output. Here we simply fake hdfs output
    # so it only runs one time.
    #    
    delete_tweet_loader.output << next_output(:load_delete_tweets)
    delete_tweet_loader.run unless hdfs.exists? latest_output(:load_delete_tweets)
    hdfs.mkpath(latest_output(:load_delete_tweets))
  end

  task :load_geo => [:unsplice] do
    expected_input = File.join(latest_output(:unsplice), 'geo')
    next unless hdfs.exists? expected_input
    geo_loader.env['PIG_OPTS'] = Settings['hadoop']['pig_options']
    geo_loader.attributes = {
      :jars         => Settings['hbase']['jars'],
      :data         => expected_input,
      :table        => Settings['hbase']['geo_table'],
      :hbase_config => Settings['hbase']['config']            
    }

    #
    # Since this script is loading geo objects directly into hbase
    # it does not produce any hdfs output. Here we simply fake hdfs output
    # so it only runs one time.
    #        
    geo_loader.output << next_output(:load_geo)
    geo_loader.run unless hdfs.exists? latest_output(:load_geo)
    hdfs.mkpath(latest_output(:load_geo))
  end

  task :load_screen_names => [:unsplice] do
    expected_input = File.join(latest_output(:unsplice), 'twitter_user')
    next unless hdfs.exists? expected_input
    screen_name_loader.env['PIG_OPTS'] = Settings['hadoop']['pig_options']
    screen_name_loader.attributes = {
      :jars         => Settings['hbase']['jars'],
      :data         => expected_input,
      :table        => Settings['hbase']['users_table'],
      :hbase_config => Settings['hbase']['config']                  
    }

    #
    # Since this script is loading twitter_user objects directly into hbase
    # it does not produce any hdfs output. Here we simply fake hdfs output
    # so it only runs one time.
    #            
    screen_name_loader.output << next_output(:load_screen_names)
    screen_name_loader.run unless hdfs.exists? latest_output(:load_screen_names)
    hdfs.mkpath(latest_output(:load_screen_names))
  end

  task :load_search_ids => [:unsplice] do
    expected_input = File.join(latest_output(:unsplice), 'twitter_user_search_id')
    next unless hdfs.exists? expected_input
    search_id_loader.env['PIG_OPTS'] = Settings['hadoop']['pig_options']
    search_id_loader.attributes = {
      :jars         => Settings['hbase']['jars'],
      :data         => expected_input,
      :table        => Settings['hbase']['users_table'],
      :hbase_config => Settings['hbase']['config']                        
    }

    #
    # Since this script is loading twitter_user objects directly into hbase
    # it does not produce any hdfs output. Here we simply fake hdfs output
    # so it only runs one time.
    #                
    search_id_loader.output << next_output(:load_search_ids)
    search_id_loader.run unless hdfs.exists? latest_output(:load_search_ids)
    hdfs.mkpath(latest_output(:load_search_ids))
  end

  task :load_user_ids => [:unsplice] do
    expected_input = File.join(latest_output(:unsplice), 'twitter_user')
    next unless hdfs.exists? expected_input
    user_id_loader.env['PIG_OPTS'] = Settings['hadoop']['pig_options']
    user_id_loader.attributes = {
      :jars         => Settings['hbase']['jars'],
      :data         => expected_input,
      :table        => Settings['hbase']['users_table'],
      :hbase_config => Settings['hbase']['config']                              
    }

    #
    # Since this script is loading twitter_user objects directly into hbase
    # it does not produce any hdfs output. Here we simply fake hdfs output
    # so it only runs one time.
    #                    
    user_id_loader.output << next_output(:load_user_ids)
    user_id_loader.run unless hdfs.exists? latest_output(:load_user_ids)
    hdfs.mkpath(latest_output(:load_user_ids))
  end

  task :load_profiles => [:unsplice] do
    expected_input = File.join(latest_output(:unsplice), 'twitter_user_profile')
    next unless hdfs.exists? expected_input
    profile_loader.env['PIG_OPTS'] = Settings['hadoop']['pig_options']
    profile_loader.attributes = {
      :jars         => Settings['hbase']['jars'],
      :data         => expected_input,
      :table        => Settings['hbase']['users_table'],
      :hbase_config => Settings['hbase']['config']                                    
    }

    #
    # Since this script is loading twitter_user objects directly into hbase
    # it does not produce any hdfs output. Here we simply fake hdfs output
    # so it only runs one time.
    #                        
    profile_loader.output << next_output(:load_profiles)
    profile_loader.run unless hdfs.exists? latest_output(:load_profiles)
    hdfs.mkpath(latest_output(:load_profiles))
  end

  task :load_styles => [:unsplice] do
    expected_input = File.join(latest_output(:unsplice), 'twitter_user_style')
    next unless hdfs.exists? expected_input
    style_loader.env['PIG_OPTS'] = Settings['hadoop']['pig_options']
    style_loader.attributes = {
      :registers    => Settings['hbase']['jars'],
      :data         => expected_input,
      :table        => Settings['hbase']['users_table'],
      :hbase_config => Settings['hbase']['config']                                          
    }

    #
    # Since this script is loading twitter_user objects directly into hbase
    # it does not produce any hdfs output. Here we simply fake hdfs output
    # so it only runs one time.
    #                            
    style_loader.output << next_output(:load_styles)
    style_loader.run unless hdfs.exists? latest_output(:load_styles)
    hdfs.mkpath(latest_output(:load_styles))
  end

  task :process_latest => [
    :rectify_rels,
    # :index_tweets,
    :load_tweets,
    :load_tokens,
    :load_a_atsigns_b,
    :load_a_follows_b,
    :load_delete_tweets,
    :load_geo,
    :load_screen_names,
    :load_search_ids,
    :load_user_ids,
    :load_profiles,
    :load_styles
  ]

end

flow.workdir = Settings['workflow']['work_dir']
flow.describe
flow.run(:process_latest)
# flow.clean!
