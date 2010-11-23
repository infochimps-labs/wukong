#!/usr/bin/env ruby
require 'rubygems'
require 'wukong'
require 'wukong/periodic_monitor'
require 'wukong/store/cassandra'
require 'wukong/script/cassandra_loader_script'

Settings.use :commandline
Settings.define :log_interval,    :default => 1
Settings.cassandra_keyspace   = 'soc_net_tw'
Settings.cassandra_col_family = 'TwitterUser'
Settings.cassandra_hosts      = "ip-10-204-41-193.ec2.internal:9160,ip-10-204-30-11.ec2.internal:9160,ip-10-204-58-238.ec2.internal:9160,ip-10-204-239-133.ec2.internal:9160,ip-10-196-191-31.ec2.internal:9160,ip-10-204-103-21.ec2.internal:9160,ip-10-202-74-223.ec2.internal:9160,ip-10-202-143-95.ec2.internal:9160"
Settings.resolve!

require 'cassandra/0.7'
require 'wuclan/twitter' ; include Wuclan::Twitter
require 'wuclan/twitter/cassandra_db'
require 'wukong/store/cassandra/streaming'

# hdp-catd s3://s3hdfs.infinitemonkeys.info/data/sn/tw/fixd/objects/twitter_user | head

# CassandraScript.new(Wukong::Store::Cassandra::StructLoader, nil).run
Wukong::CassandraScript.new(Wukong::Store::Cassandra::StructLoader, nil).run

