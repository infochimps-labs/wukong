#!/usr/bin/env ruby

require 'rubygems'
require 'wukong'
require 'wukong/periodic_monitor'
require 'wuclan/twitter' ; include Wuclan::Twitter
require 'wuclan/twitter/cassandra_db'

Settings.define :log_interval, :default => 10_000

class ObjectLoader < Wukong::Streamer::StructStreamer
  def initialize *args
    super(*args)
    @log = PeriodicMonitor.new
  end

  #
  # Blindly expects objects streaming by to have a "streaming_save" method
  #
  def process object, *_
    object.save
    # object.streaming_save
    @log.periodically(object.to_flat)
  end
end

Wukong::Script.new(ObjectLoader, nil).run
