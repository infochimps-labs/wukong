#!/usr/bin/env jruby

#
# Runs the full geo ingestion workflow on geojson records. See the config file
# to change which records this operates on.
#

#
# Broken into three distinct workflows: the core ingestion_workflow, a per-source workflow,
#   and a per-layer workflow. Each is factoried from a function of the same name, to prevent
#   reentrant interactions between unrelated sources and layers.
#

require 'rubygems'
require 'swineherd' ; include Swineherd
require 'swineherd/script/pig_script' ; include Swineherd::Script
require 'swineherd/script/wukong_script'
require 'stargate'

# Get the core, command line, and environmental settings
Settings.define 'workflow.sources', :default => 'all'
Settings.use :commandline
Settings.read File.expand_path('./config/base.yaml')
Settings.resolve!

Hdfs = Swineherd::FileSystem.get :hdfs
S3   = Swineherd::FileSystem.get :hdfs, :filesystem => Settings['workflow']['s3_bucket']

Log.level       = Logger.const_get Settings['log_level']
RakeFileUtils.verbose(false) unless Log.debug?
Settings['hadoop']['pig_options'] << "-Ddebug=#{Log.level.to_s}"

Lib = File.dirname(__FILE__)+'/lib'



#
# TODO: remove the following to a (set of) libraries?
#

#
# Examine a directory and generate a list of layers
#
def get_layers dir
  Hdfs.entries(dir).map{|x| File.basename(x)}.reject{|x| x.start_with?("_") || x == "null"}
end

#
# Given a workflow.sources setting, return an array of all valid config files
# 
def source_cfgs
  case Settings['workflow']['sources']
  when 'all' then Dir.glob("./config/sources/*.yaml")
  else
    sources = Settings['workflow']['sources']
    sources = [ sources ] unless sources.kind_of? Array
    Settings['workflow']['sources'].map do |s| 
      f = "./config/sources/#{s}.yaml"
      f if File.exists? f
    end.compact
  end
end





#
# Creates the elasticsearch index specified by index_name. This is disgusting.
#
def create_es_index index_name, config
  es_options  = YAML.load(File.read(config))
  data_esnode = es_options['discovery']['zen']['ping']['unicast']['hosts'].split(',').first.split(":").first
  port = "9200"
  sh "curl -s -XPUT \"http://%s:%s/%s/\"" % [data_esnode, port, index_name]
end

#
# Puts standard geo mapping for object_type in index_name
#
def put_es_mapping index_name, object_type, config
  es_options  = YAML.load(File.read(config))
  data_esnode = es_options['discovery']['zen']['ping']['unicast']['hosts'].split(',').first.split(":").first
  port = "9200"
  mapping = {
    object_type => {
      "properties" => {
        "md5id" => {
          "store" => "yes",
          "type"  => "string"
        },
        "coordinates" => {
          "store" => "yes",
          "type"  => "geo_point"
        },
        "_region" => {
          "store" => "yes",
          "type"  => "boolean"
        }
      }
    }
  }.to_json
  Log.info "putting mapping \n[#{mapping}}] \n to elasticsearch"
  sh "curl -s -XPUT \"http://%s:%s/%s/%s/_mapping\" -d '%s'" % [data_esnode, port, index_name, object_type, mapping]
end



#
# Creates the HBase table and column family
#
def create_hb_table table_name, column_family
  client = Stargate::Client.new("http://10.195.218.111:8080")

  table_names    = client.list_tables.map{|table| table.name}
  current_tables = table_names.inject({}){|hsh,name| hsh[name] = client.show_table(name).column_families.map{|cf| cf.name}; hsh}

  return if current_tables.keys.include?(table_name) && current_tables[table_name].include?(column_family)
  client.create_table(table_name, column_family)
end



module TaskMixins
  def prep_attributes attributes
    attributes[:jars]        ||= Settings['hadoop']['jars']
    attributes[:out]         ||= next_output(attributes[:name])
    attributes[:pig_options] ||= Settings['hadoop']['pig_options'].join(' ')
    attributes
  end
  
  # 
  # Do an action only once, writing to a marker on the HDFS if successful (block returns true)
  # 
  def only_once attributes
    marker = attributes[:out] + '/_success'
    unless Hdfs.exists?(marker)
      success = yield
      message = "Stored #{attributes[:name]} successfully at " + Time.now.to_s
      Hdfs.open(marker,'w').write(message) if success
    else
      success = true
      Log.info attributes[:name].to_s + ' has already been done, skipping'
    end
    success
  end

  def pig_job attributes
    pig = PigScript.new(File.join(Lib, "#{attributes[:name].to_s}.pig.erb"))
    pig.attributes = attributes
    pig.env['PIG_OPTS'] = attributes[:pig_options]

    Log.info "Running pig job '#{attributes[:name]}'"
    Log.debug attributes
    Log.debug File.read(pig.script)
    pig.run
  end

  def hdfs_pig_job attributes
    attributes = prep_attributes attributes
    only_once attributes do
      Hdfs.rm attributes[:out]
      yield if block_given?
      pig_job attributes
    end
  end

  def s3_pig_job attributes
    attributes = prep_attributes attributes
    only_once attributes do
      attributes[:out] = attributes[:s3_bucket] + attributes[:out]
      S3.rm attributes[:out]
      yield if block_given?
      pig_job attributes
    end
  end
end

#
# Factory the main ingestion workflow
# 
def ingestion_workflow
  Workflow.new('ingestion_workflow') do
    #
    # Get the isa_mapping, core_regions, and tiled_clusters from S3 and cache them to HDFS
    #
    task :cache_common_files do
      dir = next_output(:cache)
      Settings['cache'] = {}

      Settings['workflow']['common_files'].each do |name,source|
        cache = PigScript.new(File.join(Lib, 'cache.pig.erb'))
        cache.env['PIG_OPTS'] = Settings['hadoop']['pig_options'].join(' ')
        jobname = "cache_#{name}"
        target = "#{dir}/#{name}"
        cache.attributes = {
          :name     => jobname,
          :input    => source,
          :output   => target
        }
        Log.info "Running task '#{jobname}'"
        Log.debug File.read(cache.script)
        cache.run(:hadoop) unless Hdfs.exists? target
        Settings['cache'][name] = target
      end
    end

    #
    # Parse layers and store results into S3
    #
    task :prepare_from_sources => :cache_common_files do
      source_cfgs.each do |source_cfg|
        Log.info "Preparing #{source_cfg}'"
        source_flow = source_workflow source_cfg
        source_flow.workdir = "/tmp/geoadventure/ingestion_workflow"
        source_flow.run :prepare_layers
      end
    end

    #
    # Store layers into HBase and ElasticSearch
    #
    task :store_results => :cache_common_files do
      source_cfgs.each do |source_cfg|
        Log.info "Storing #{source_cfg}"
        source_flow = source_workflow source_cfg
        source_flow.workdir = "/tmp/geoadventure/ingestion_workflow"
        source_flow.run :store_layers
      end
    end

  end
end

#
# Factory the per-source workflow
# 
def source_workflow source_cfg
  sourceSettings = Settings.clone
  sourceSettings.read File.expand_path(source_cfg)
  sourceSettings.resolve!
  dataset = sourceSettings['dataset'] = sourceSettings['icss']['namespace'] +'.'+ sourceSettings['icss']['protocol']

  Workflow.new(dataset) do
    self.extend TaskMixins
    
    #
    # Split the geojson into its various layers
    #
    task :split_into_layers do
      hdfs_pig_job({
        :name    => :split_into_layers,
        :geojson => sourceSettings['workflow']['input'],
        :isa_mapping => sourceSettings['cache']['isa_mapping']
      })
    end

    #
    # Prepare each layer one at a time
    #
    task :prepare_layers => :split_into_layers do
      layers = get_layers(latest_output(:split_into_layers))
      layers.each do |layer|
        location      = File.join(latest_output(:split_into_layers), layer)

        layer_flow = layer_workflow layer, location, sourceSettings
        layer_flow.workdir = "/tmp/geoadventure/ingestion_workflow"

        ['points','tiles','regions'].each do |type|
          job = "prepare_#{type}"
          patterns = [ type, "#{type}.#{layer}", job, "#{job}.#{layer}" ]
          unless ( ( sourceSettings['workflow']['skip'] & patterns ).empty? )
            Log.info "Skipping task '#{job}' on '#{layer}', per config"
            next
          end
          Log.info "Running task '#{job}' on '#{layer}'"
          layer_flow.run(job.to_sym)
        end
      end
    end

    #
    # Store each layer one at a time
    #
    task :store_layers => :split_into_layers do
      layers = get_layers(latest_output(:split_into_layers))
      layers.each do |layer|
        location      = File.join(latest_output(:split_into_layers), layer)

        layer_flow = layer_workflow layer, location, sourceSettings
        layer_flow.workdir = "/tmp/geoadventure/ingestion_workflow"

        ['points','tiles','regions'].each do |type|
          job = "store_#{type}"
          patterns = [ type, "#{type}.#{layer}", job, "#{job}.#{layer}" ]
          unless ( ( sourceSettings['workflow']['skip'] & patterns ).empty? )
            Log.info "Skipping task '#{job}' on '#{layer}', per config"
            next
          end
          Log.info "Running task '#{job}' on '#{layer}'"
          layer_flow.run(job.to_sym)
        end
      end
    end

  end
end

#
# Factory the per-layer workflow
# 
def layer_workflow layer, location, sourceSettings
  dataset = sourceSettings['dataset']
  Workflow.new("#{dataset}/layer-#{layer}") do
    self.extend TaskMixins
    #
    # Attaches md5ids to all geoJSON in the layer
    #
    task :attach_ids do
      hdfs_pig_job({
        :name      => :attach_ids,
        :geojson   => location,
        :layer     => layer,
        :dataset   => dataset
      })
    end

    #
    # Splits incoming geoJSON into two groups, points and non points
    #
    task :split_by_geometry => :attach_ids do
      hdfs_pig_job({
        :name       => :split_by_geometry,
        :geojson    => latest_output(:attach_ids)
      })
    end

    #
    # Determines the set of core regions that points are inside
    #
    task :points_inside_regions => :split_by_geometry do
      hdfs_pig_job({
        :name           => :points_inside_regions,
        :contain_script => File.join(Lib, 'containing_geometries.rb'),
        :reduce_tasks   => sourceSettings['hadoop']['reduce_tasks'],
        :core_regions   => sourceSettings['cache']['core_regions'],
        :geojson        => File.join(latest_output(:split_by_geometry), 'points')
      })
    end

    #
    # Computes the centroids of regions.
    #
    task :compute_centroids => :split_by_geometry do
      hdfs_pig_job({
        :name          => :compute_centroids,
        :geojson       => File.join(latest_output(:split_by_geometry), 'non_points')
      })
    end

    #
    # Converts geoJSON points into Infochimps Things
    #
    task :points_to_things => [:points_inside_regions, :compute_centroids] do
      points = [latest_output(:points_inside_regions), latest_output(:compute_centroids)].join(",")
      hdfs_pig_job({
        :name          => :points_to_things,
        :geojson       => points
      })
    end

    #
    # Collect large numbers of points into clusters
    # Generates clusters from ZL=[1,15] and points from ZL=[16,22] 
    #
    task :cluster_points => :points_inside_regions do
      hdfs_pig_job({
        :name             => :cluster_points,
        :reduce_tasks     => sourceSettings['hadoop']['reduce_tasks'],
        :geojson          => latest_output(:points_inside_regions),
        :initial_clusters => sourceSettings['cache']['tiled_clusters'],
        :dataset          => dataset,
        :layer            => layer
      })
    end

    #
    # Take centroids and points, prepares them for the ElasticSearch point store, and stuffs them on S3
    #
    task :prepare_points => :points_to_things do
      s3_pig_job({
        :name       => :prepare_points,
        :bulk_size  => 500,
        :points     => latest_output(:points_to_things),
        :layer      => layer,
        :s3_bucket  => sourceSettings['workflow']['s3_bucket']
      })
    end

    #
    # Takes tiles, prepares them for the HBase tile store, and stuffs them on S3
    #
    task :prepare_tiles => :cluster_points do
      s3_pig_job({
        :name         => :prepare_tiles,
        :geojson      => latest_output(:cluster_points),
        :points       => File.join(latest_output(:cluster_points), 'points'),
        :clusters     => File.join(latest_output(:cluster_points), 'clusters'),
        :layer        => layer,
        :s3_bucket    => sourceSettings['workflow']['s3_bucket']
      })
    end

    #
    # Takes regions, prepares them for the HBase region store, and stuffs them on S3
    #
    task :prepare_regions => :split_by_geometry do
      s3_pig_job({
        :name         => :prepare_regions,
        :geojson      => File.join(latest_output(:split_by_geometry), 'non_points'),
        :region_table => sourceSettings['hbase']['core_regions_table'],
        :s3_bucket    => sourceSettings['workflow']['s3_bucket']
      })
    end

    task :store_points => :prepare_points do
      hdfs_pig_job({
        :name       => :store_points,
        :bulk_size  => 500,
        :es_config  => sourceSettings['elasticsearch']['config'],
        :es_plugins => sourceSettings['elasticsearch']['plugins'],
        :points     => sourceSettings['workflow']['s3_bucket'] + latest_output(:prepare_points),
        :dataset    => dataset,
        :layer      => layer
      }) do
        create_es_index(dataset, Settings['elasticsearch']['config'])
        put_es_mapping(dataset, layer, Settings['elasticsearch']['config'])
      end
    end

    task :store_tiles => :prepare_tiles do
      hdfs_pig_job({
        :name         => :store_tiles,
        :tiles        => sourceSettings['workflow']['s3_bucket'] + latest_output(:prepare_tiles),
        :hbase_config => File.expand_path( sourceSettings['hbase']['config'] ),
        :dataset      => dataset,
        :layer        => layer
      }) do
        create_hb_table(dataset, "clusters")
        create_hb_table(dataset, "points")
      end
    end

    task :store_regions => :prepare_regions do
      hdfs_pig_job({
        :name         => :store_regions,
        :geojson      => sourceSettings['workflow']['s3_bucket'] + latest_output(:prepare_regions),
        :region_table => sourceSettings['hbase']['core_regions_table'],
        :hbase_config => File.expand_path( Settings['hbase']['config'] )
      })
    end

  end
end




Log.info("Running ingestion workflow on #{Settings['workflow']['sources']} sources")
main = ingestion_workflow
main.workdir = '/tmp/geoadventure'
main.run(:prepare_from_sources)              
#main.run(:store_results)
