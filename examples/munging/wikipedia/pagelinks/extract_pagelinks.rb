#!/usr/bin/env ruby

require 'wukong'
require 'wukong/streamer/sql_streamer'

module PagelinksExtractor
  class Mapper < Wukong::Streamer::SQLStreamer
    #TODO: Add encoding guard
    columns [:int, :int, :string]
  end
end

Wukong::Script.new(PagelinksExtractor::Mapper, nil).run
