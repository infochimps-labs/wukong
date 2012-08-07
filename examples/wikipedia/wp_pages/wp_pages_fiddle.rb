#!/usr/bin/env ruby

require 'wukong'

load '/home/dlaw/dev/wukong/examples/wikipedia/munging_utils.rb'

module PagesToTSV
  class Mapper < Wukong::Streamer::LineStreamer

    COLUMNS=  [:int, :int, :string, :string, :int, 
               :int, :int, :float, :string, :int, :int]
  
    def initialize
      @sql_parser = MungingUtils::SQLParser.new(COLUMNS)
    end

    def process(line, &blk)
      @sql_parser.parse(line,&blk)
    end
  end
end

# go to town
Wukong::Script.new(
  PagesToTSV::Mapper,
  nil
).run
