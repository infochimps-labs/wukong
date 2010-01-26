#!/usr/bin/env ruby
# run like so:
# $> ruby sizes.rb --run=local data/orders.tsv data/sizes
require 'rubygems'
require 'wukong'

module JeanSizes
  class Mapper < Wukong::Streamer::RecordStreamer
    def process(code,model,time,country,reg,col, n1,c1, venue,n3,n4, *sizes)
      yield [country, *sizes]
    end
  end

  #
  # This uses a ListReducer. It's nice and simple, but requires first
  # accumulating each key's records in memory.
  #
  class JeansListReducer < Wukong::Streamer::ListReducer
    def finalize
      return if values.empty?
      sums = []; 13.times{ sums << 0 }
      values.each do |country, *sizes|
        sizes.map!(&:to_i)
        sums = sums.zip(sizes).map{|sum, val| sum + val }
      end
      yield [key, *sums]
    end
  end


  #
  # This uses an AccumulatingReducer directly.
  # It has the advantage of a minimal footprint.
  #
  class JeansAccumulatingReducer < Wukong::Streamer::AccumulatingReducer
    attr_accessor :sums

    # start the sum with 0 for each size
    def start! *_
      self.sums = []; 13.times{ self.sums << 0 }
    end
    # accumulate each size count into the sizes_sum
    def accumulate country, *sizes
      sizes.map!(&:to_i)
      self.sums = self.sums.zip(sizes).map{|sum, val| sum + val }
    end
    # emit [country, size_0_sum, size_1_sum, ...]
    def finalize
      yield [key, sums].flatten
    end
  end

end

Wukong::Script.new(JeanSizes::Mapper, JeanSizes::JeansListReducer).run
