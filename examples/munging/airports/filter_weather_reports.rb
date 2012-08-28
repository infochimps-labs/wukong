#!/usr/bin/env ruby
# encoding:UTF-8

require 'wukong'
require 'pathname'
load '/home/dlaw/dev/wukong/examples/wikipedia/munging_utils.rb'

module WeatherFilter
  class Mapper < Wukong::Streamer::LineStreamer

    WBAN_FILENAME = '/home/dlaw/dev/wukong/examples/airports/wbans.txt'
    USA_WBAN_FILENAME = '/home/dlaw/dev/wukong/examples/airports/usa_wbans.txt'
    FORTY_WBANS_FILENAME = '/home/dlaw/dev/wukong/examples/airports/40_wbans.txt'

    def initialize
      @wbans = []
      wban_file = File.open(FORTY_WBANS_FILENAME)
      wban_file.each_line do |line|
        @wbans << line[0..-2]
      end
    end

    def process line
      MungingUtils.guard_encoding(line) do |clean_line|
        wban = Pathname(ENV['map_input_file']).basename.to_s.split('-')[1]
        if @wbans.include? wban
          yield line
        end
      end
    end
  end
end

Wukong::Script.new(
  WeatherFilter::Mapper,
  nil
).run
