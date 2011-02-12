#!/usr/bin/env ruby -E ASCII-8BIT
require 'rubygems'
require 'wukong/script'
$: << File.dirname(__FILE__)
require 'logline'

class ApacheLogParser < Wukong::Streamer::LineStreamer

  # create a Logline object from each record and serialize it flat to disk
  def process line
    yield Logline.parse(line)
  end
end

Wukong.run( ApacheLogParser, nil, :sort_fields => 7 ) if $0 == __FILE__




