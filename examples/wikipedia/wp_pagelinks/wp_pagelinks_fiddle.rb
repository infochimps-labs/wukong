#!/usr/bin/env ruby
require 'wukong'

load '/home/dlaw/dev/wukong/examples/wikipedia/munging_utils.rb'

module PagelinksToTSV
  class Mapper < Wukong::Streamer::LineStreamer

    COLUMNS = [:int, :int, :string]

    def initialize
      @sql_parser = MungingUtils::SQLParser.new(COLUMNS)
    end

    def process(line, &blk)
      @sql_parser.parse(line, &blk)
    end
  end
end

# go to town
Wukong::Script.new(
  PagelinksToTSV::Mapper,
  nil
).run
