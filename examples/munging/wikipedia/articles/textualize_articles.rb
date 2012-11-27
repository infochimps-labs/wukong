#!/usr/bin/env ruby

# Generate plain-text versions of articles from the tsv-converted raw article data
# (output from extract_articles)
#
# This strips out template tags, wiki links, and so forth
#
# Everything that's left is either actual text, or nicely detached punctuation.

require 'wukong'
require 'multi_json'
require_relative '../utils/munging_utils.rb'
require_relative 'wp2txt/lib/wp2txt/article'

require 'crack/xml'

module TextualizeArticles

  class Mapper < Wukong::Streamer::RecordStreamer
    include MungingUtils

    @@errors   = 0
    MAX_ERRORS = 1_000

    def process title, namespace, id, restrictions, revision_id, timestamp, sha1='', redirect='', raw_text=''
      text          = MultiJson.decode(raw_text)
      article       = Wp2txt::Article.new(text, title)
      jsonized_text = MultiJson.encode(article.polish)

      yield [title, namespace, id, revision_id, timestamp, redirect, jsonized_text]

    rescue StandardError => err
      Wukong.bad_record("Bad Record", err, record)
      raise "Too many errors" if (@@errors += 1) > MAX_ERRORS
    end

  end
end

Wukong::Script.new(TextualizeArticles::Mapper, nil).run
