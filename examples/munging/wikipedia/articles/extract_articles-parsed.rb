#!/usr/bin/env ruby

# Extracts wikipedia articles from bzipped xml, outputs them in TSV.  Article
# text is XML encoded, but all newlines and tabs (in fact, all control
# characters) are converted to XML entities, making it safe to truck around as
# TSV.
#
# Sample Pig LOAD Statement:
#
# all_articles = LOAD '$articles' AS
#   (id:long, namespace:int, title:chararray, revision_timestamp:long, redirect:chararray, text:chararray);
#

require 'wukong'
require 'wukong/streamer/encoding_cleaner'
require 'crack/xml'
require 'multi_json'
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
        result = Crack::XML::parse(lines.join("\n"))
        @lines = []
        return [result]
      else
        return nil
      end
    end

    def process record
      if record.has_key? 'mediawiki'
        record = record['mediawiki']
      end

      redirect  = record['page']['redirect'] ? record['page']['redirect']['title'] : ''
      timestamp = Time.iso8601(record['page']['revision']['timestamp']).to_flat
      raw_text  = record['page']['revision']['text']
      
      # some few parts per million articles have an empty body -- workaround
      raw_text = '' if not record['page']['revision']['text'].is_a?(String)

      result = [
        record['page']['id'],
        record['page']['ns'],
        scrub_control_chars(record['page']['title']),
        record['page']['revision']['id'],
        timestamp,
        scrub_control_chars(redirect),
        MultiJson.encode(raw_text)
      ]
      yield result
    end
  end
end

# Force it to run in a single map task, to avoid writing a custom input format.
# The job runs in 2 hours, once; much less than the time it'd take me to do so.
Wukong::Script.new(ArticlesExtractor::Mapper, nil, min_split_size: 1152921504606846976).run
