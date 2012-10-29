#!/usr/bin/env ruby

#  This script extracts wikipedia articles from bzipped xml and outputs
#  them in TSV. 
#
#  Sample Pig LOAD Statement:
#  all_articles = LOAD '$articles' AS 
#    (id:int, title:chararray, namespace:int, revision_date:int, revision_time:int, 
#    revision_epoch_time:long, revision_day_of_week:int, text:chararray);

require 'wukong'
require 'wukong/streamer/encoding_cleaner'
require 'crack/xml'
require_relative '../utils/munging_utils.rb'

module ArticlesExtractor
  class Mapper < Wukong::Streamer::LineStreamer
    include Wukong::Streamer::EncodingCleaner
    include MungingUtils

    def lines
      @lines ||= []
    end

    def recordize line
      lines << line
      if line =~ /<\/page>/
        result = Crack::XML::parse(lines.join)
        @lines = []
        return [result]
      else
        return nil
      end
    end

    def escape text
      text.gsub!(/\n/,"&#10;");
      text.gsub!(/\t/,"&#09;");
      return text
    end

    def process record
      if record.has_key? 'mediawiki'
        record = record['mediawiki']
      end
      result = []
      result << record['page']['id']
      result << record['page']['title']
      result << record['page']['ns']
      result += time_columns_from_time(Time.iso8601(record['page']['revision']['timestamp']))
      result << escape(record['page']['revision']['text'])
      yield result
    end
  end
end

Wukong::Script.new(ArticlesExtractor::Mapper,nil).run
