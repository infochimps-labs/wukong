#!/usr/bin/env ruby

# Generate plain-text versions of articles from the tsv-converted raw article data
# (output from extract_articles)
#
# This strips out template tags, wiki links, and so forth
#
# Everything that's left is either actual text, or nicely detached punctuation.

# ## Usage
#
# Uses the output of extract_articles-templated.rb:
#
#    examples/munging/wikipedia/articles/textualize_articles.rb --rm --run \
#      /data/results/wikipedia/full/articles.json.tsv      \
#      /data/results/wikipedia/full/article_texts.json.tsv
#

require 'wukong'
require 'multi_json'
require 'oj'
require 'strscan'
require 'find'
require 'sanitize'
#
require_relative '../utils/munging_utils.rb'
require_relative './wp2txt_article'
require_relative './wp2txt_utils'

module TextualizeArticles

  class Mapper < Wukong::Streamer::RecordStreamer
    include MungingUtils

    @@errors   = 0
    MAX_ERRORS = 1_000

    def process(id, namespace, title, revision_id, timestamp, redirect, raw_text)

      text          = MultiJson.decode(raw_text)
      article       = Wp2txt::Article.new(text, title)
      jsonized_text = MultiJson.encode(article.polish)

      yield [id, namespace, title, revision_id, timestamp, redirect, jsonized_text]

    rescue StandardError => err
      Wukong.bad_record("Bad Record", err, raw_text)
      raise "Too many errors" if (@@errors += 1) > MAX_ERRORS
    end

  end
end

Wukong::Script.new(TextualizeArticles::Mapper, nil).run
