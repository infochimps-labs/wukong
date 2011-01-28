#!/usr/bin/env ruby
require 'rubygems'
require 'avro'
require 'wukong'
require 'wukong/periodic_monitor'
Settings.define :log_interval, :default => 10_000

require 'digest/md5'
Settings.define :ring_nodes

MAX_HASH = 2**127
RING_NODES = 72
RING_WIDTH = MAX_HASH / RING_NODES
OUT_DIR    = '/mnt/tmp/partitioned_words'

# for foo in pw0/part-000* ; do echo $foo ; time cat $foo | ~/ics/wukong/examples/cassandra_streaming/cassandra_random_partitioner.rb --map 2>/tmp/split-`basename $foo`.log & done 

module CassandraRandomPartitioner
  def partition_hash key
    uval = Digest::MD5.hexdigest(key).to_i(16)
    (uval > 2**127) ? (2**128 - uval) : uval
  end

  def partition key
    partition_hash(key) / RING_WIDTH
  end
  
  def files
    @files ||= Hash.new{|h,part| h[part] = File.open(OUT_DIR+"/chunk-#{"%03d" % part}", 'w') }
  end

end

module PeriodicLog
  def log
    @log ||= PeriodicMonitor.new
  end  
end

class HashingStreamer < Wukong::Streamer::RecordStreamer
  include CassandraRandomPartitioner
  include PeriodicLog

  def process word, count, *_
    log.periodically( word, count )
    part = partition(word)
    # yield [part, word, count]
    files[part] << [word, count].join("\t") << "\n"
  end
end

class HashingReducer <  Wukong::Streamer::RecordStreamer
  include CassandraRandomPartitioner
  include PeriodicLog

  def process part, word, count, *_
    log.periodically( word, count )
    yield [word, count]
  end
end

Wukong::Script.new(HashingStreamer, HashingReducer, :map_speculative => false).run
