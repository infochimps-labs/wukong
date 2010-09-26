#!/usr/bin/env ruby
require 'rubygems'
require 'wukong'
require 'wukong/store/cassandra'

# hdp-catd s3://s3hdfs.infinitemonkeys.info/data/sn/tw/fixd/objects/twitter_user | head

::CASSANDRA_DB_SEEDS = %w[ 10.244.42.4 ].map{|s| "#{s}:9160"}.sort_by{ rand }

require 'cassandra/0.7'
require 'wukong'
require 'wukong/periodic_monitor'
require 'wuclan/twitter' ; include Wuclan::Twitter
require 'wuclan/twitter/cassandra_db'

Settings.define :log_interval,    :default => 1
Settings.define :dest_keyspace,   :default => 'soc_net_tw'
Settings.define :dest_col_family, :default => 'TwitterUser'
Settings.define :cassandra_home,  :env_var => 'CASSANDRA_HOME', :default => '/usr/local/share/cassandra'

# CassandraScript.new(Wukong::Store::Cassandra::StructLoader, nil).run
Wukong::Script.new(Wukong::Store::Cassandra::StructLoader, nil).run

