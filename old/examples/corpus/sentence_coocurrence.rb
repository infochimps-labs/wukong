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
class SentenceCoocurrence < Wukong::Streamer::RecordStreamer
  def initialize *args
    super *args
    @bucket = BucketCounter.new
  end

  def process title, idx, *words
    @bucket << words[0..-2].zip(words[1..-1])
    dump_bucket if @bucket.full?
  end

  def dump_bucket
    @bucket.each do |pair_key, count|
      emit [pair_key, count]
    end
    $stderr.puts "bucket stats: #{@bucket.stats.inspect}"
    @bucket.clear
  end

  def after_stream
    dump_bucket
  end
end

#
# Combine multiple bucket counts into a single on
#
class CombineBuckets < Wukong::Streamer::AccumulatingReducer
  def start! *args
    @total = 0
  end
  def accumulate word, count
    @total += count.to_i
  end
  def finalize
    yield [@total, key] if @total > 20
  end
end

Wukong.run(
  SentenceCoocurrence,
  CombineBuckets,
  :io_sort_record_percent => 0.3,
  :io_sort_mb => 300
  )
