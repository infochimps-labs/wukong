#!/usr/bin/env ruby
$LOAD_PATH.unshift File.expand_path('../../lib', File.dirname(__FILE__))
require          'wukong/script'
require_relative './logline'

class ApacheLogParser < Wukong::Streamer::LineStreamer
  # create a Logline object from each record and serialize it flat to disk
  def process line
    yield Logline.parse(line)
  end
end

Wukong.run( ApacheLogParser )
