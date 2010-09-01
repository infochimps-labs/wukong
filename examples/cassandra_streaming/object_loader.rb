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

Settings.define :log_interval, :default => 3

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
    opts
  end
end

CassandraScript.new(ObjectLoader, nil).run
