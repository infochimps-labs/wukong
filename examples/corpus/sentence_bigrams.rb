#!/usr/bin/env ruby
$: << File.dirname(__FILE__)
require 'rubygems'
require 'wukong/script'
require 'bucket_counter'

#
# Coocurrence counts
#

#
# Input is a list of document-idx-sentences, each field is tab-separated
#   title   idx   word_a    word_b    word_c ...
#
# This emits each co-courring pair exactly once; in the case of a three-word
# sentence the output would be
#
#   word_a  word_b
#   word_a  word_c
#   word_b  word_c
#
class SentenceBigrams < Wukong::Streamer::RecordStreamer
  def process title, idx, *words
    words[0..-2].zip(words[1..-1]).each do |word_a, word_b|
      yield [word_a, word_b]
    end
  end
end

#
# Combine multiple bucket counts into a single on
#
class CombineBuckets < Wukong::Streamer::AccumulatingReducer
  def get_key *fields
    fields[0..1]
  end
  def start! *args
    @total = 0
  end
  def accumulate *fields
    @total += 1
  end
  def finalize
    yield [@total, key].flatten
  end
end

Wukong.run(
  SentenceBigrams,
  CombineBuckets,
  :io_sort_record_percent => 0.3,
  :io_sort_mb => 300
  )
