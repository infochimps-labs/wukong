#!/usr/bin/env ruby

require 'rubygems'

::CASSANDRA_DB_SEEDS = %w[ 10.244.42.4 ].map{|s| "#{s}:9160"}.sort_by{ rand }

$: << '/home/jacob/Programming/wuclan/lib'
$: << '/home/jacob/Programming/wukong/lib'
$: << '/home/jacob/Programming/wukong/lib/wukong'
$: << '/home/jacob/Programming/wukong/lib/wukong/store'

require 'cassandra/0.7'
require 'wukong'
require 'wukong/periodic_monitor'
require 'wuclan/twitter' ; include Wuclan::Twitter
require 'wuclan/twitter/cassandra_db'

Settings.define :log_interval,    :default => 3
Settings.define :dest_keyspace,   :default => 'soc_net_tw'
Settings.define :dest_col_family, :default => 'TwitterUser'
Settings.define :cassandra_home,  :env_var => 'CASSANDRA_HOME', :default => '/usr/local/share/cassandra'

class ObjectLoader < Wukong::Streamer::StructStreamer
  def initialize *args
    super(*args)
    @log = PeriodicMonitor.new
  end

  #
  # Blindly expects objects streaming by to have a "streaming_save" method
  #
  def process object, *_
    # object.save
    object.streaming_save
    @log.periodically(object.to_flat)
  end
end

class CassandraScript < Wukong::Script
  def hadoop_other_args *args
    opts = super(*args)
    opts << "-D stream.map.output=\'cassandra_avro_output\'"
    opts << "-D stream.io.identifier.resolver.class=\'org.apache.cassandra.hadoop.streaming.AvroResolver\'"
    opts << "-D cassandra.output.keyspace=\'#{Settings.dest_keyspace}\'"
    opts << "-D cassandra.output.columnfamily=\'#{Settings.dest_col_family}\'"
    opts << "-D cassandra.partitioner.class=\'org.apache.cassandra.dht.RandomPartitioner\'"
    opts << "-D cassandra.thrift.address=\'10.244.42.4\'"
    opts << "-D cassandra.thrift.port=\'9160\'"
    opts << "-D mapreduce.output.columnfamilyoutputformat.batch.threshold=\'4090\'"
    opts << "-D mapred.max.maps.per.node=\'5\'"
    # ORDER MATTERS
    opts << "-libjars \'#{cassandra_jars}\'"
    opts << "-file    \'#{Settings.cassandra_avro_schema}\'"
    opts << "-outputformat \'org.apache.cassandra.hadoop.ColumnFamilyOutputFormat\'"
    opts
  end

  #
  # Return paths to cassandra jars as a string
  #
  def cassandra_jars
    jars = []
    Dir["#{Settings.cassandra_home}/build/apache-cassandra*.jar", "#{Settings.cassandra_home}/build/lib/jars/*.jar", "#{Settings.cassandra_home}/lib/*.jar"].each do |jar|
      jars << jar
    end
    jars.join(',')
  end

end

CassandraScript.new(ObjectLoader, nil).run
