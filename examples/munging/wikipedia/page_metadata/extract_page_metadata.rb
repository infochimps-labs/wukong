#!/usr/bin/env ruby

require 'wukong'
require 'wukong/streamer/sql_streamer'

module PageMetadataExtractor
  class Mapper < Wukong::Streamer::SQLStreamer
    #TODO: Add encoding guard
    columns [:int, :int, :string, :string, :int, 
             :int, :int, :float, :string, :int, :int]
   end
end

Wukong::Script.new(PageMetadataExtractor::Mapper, nil).run
