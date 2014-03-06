#!/usr/bin/env ruby
require_relative './common'

class ApacheLogParser < Wukong::Streamer::LineStreamer
  # create a Logline object from each record and serialize it flat to disk
  def process line
    yield Logline.parse(line)
  end
end

Wukong.run( ApacheLogParser )
