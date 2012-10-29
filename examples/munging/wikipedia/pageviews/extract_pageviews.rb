#!/usr/bin/env ruby
# encoding:UTF-8

# Pig output format:
# namespace:int, title:chararray, num_visitors:long, date:int, time:int, epoch_time:long, day_of_week:int

$:.unshift '/home/dlaw/dev/wukong_og/lib'
$:.unshift '/home/dlaw/dev/gorillib/lib'

require 'uri'
require 'pathname'
require 'json'
require 'wukong'
require 'wukong/streamer'
require 'wukong/streamer/encoding_cleaner'
load '/home/dlaw/dev/wukong/examples/munging/wikipedia/utils/munging_utils.rb'

ENV['map_input_file'] ||= 'pagecounts-20071222-100000.gz'

class String
  def is_enwiki?
    return (not (self =~ /^en /).nil?)
  end

  def is_after_enwiki?
    return (not (self =~ /^(e[o-z][a-z]*|[f-z][a-z]+) /).nil?)
  end
end

module PageviewsExtractor
  class Mapper < Wukong::Streamer::LineStreamer
    include Wukong::Streamer::EncodingCleaner
    include MungingUtils

    ns_json_file = File.open("/home/dlaw/dev/wukong/examples/munging/wikipedia/utils/namespaces.json",'r:UTF-8')
    NAMESPACES = JSON.parse(ns_json_file.read)

    # the filename strings are formatted as
    # pagecounts-YYYYMMDD-HH0000.gz
    def time_from_filename(filename)
      parts = filename.split('-')
      year = parts[1][0..3].to_i
      month = parts[1][4..5].to_i
      day = parts[1][6..7].to_i
      hour = parts[2][0..1].to_i
      return Time.new(year,month,day,hour)
    end

    def process line
      # we only want enwiki lines
      return if @done
      if line.is_after_enwiki?
        @done = true
        return
      end
      return if not line.is_enwiki?
      # we have an enwiki line - process it!
      fields = line.split(' ')[1..-1]
      out_fields = []
      # add the namespace
      namespace = nil
      if fields[0].include? ':'
        namespace = NAMESPACES[fields[0].split(':')[0]]
        out_fields << (namespace || '0')
      else
        out_fields << '0'
      end
      # add the title
      if namespace.nil?
        out_fields << URI.unescape(fields[0])
      else
        out_fields << URI.unescape(fields[0][(fields[0].index(':')||-1)+1..-1])
      end
      # add number of visitors in the hour
      out_fields << fields[2]
      # grab date info from filename
      file = Pathname.new(ENV['map_input_file']).basename
      time = time_from_filename(file.to_s)
      out_fields += time_columns_from_time(time)
      yield out_fields
    end
  end
end

Wukong::Script.new(PageviewsExtractor::Mapper, Wukong::Streamer::LineStreamer).run
