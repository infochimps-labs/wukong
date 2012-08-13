#!/usr/bin/env ruby
$: << File.dirname(__FILE__)

require 'flat/lib/flat'
require 'weather'
require 'wukong'
require 'pp'

module Weather
  class Mapper < Wukong::Streamer::LineStreamer
    FLAT_FORMAT = "_4  i6    i5   s8      s4  sD6e3  D7e3   s5   i5   s5   s4  i3 ssD4e1ii5   ssbi6    sssD5e1 sD5e1 sD5e1 ss*"

    def parser
      @parser ||= ::Flat.create_parser(FLAT_FORMAT)
    end

    def recordize line
      [parser.parse(line)]
    end

    def process record
      report = RawWeatherReport.from_tuple(*record)
      final_report = WeatherReport.new report.to_wire
      pp final_report.to_wire
    end
  end
end

Wukong::Script.new(
  Weather::Mapper,
  nil
).run
