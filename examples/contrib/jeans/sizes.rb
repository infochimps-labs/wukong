#!/usr/bin/env ruby
# run like so:
# $> ruby sizes.rb --run=local data/orders.tsv data/sizes.tsv
require 'rubygems'
require 'wukong'

module JeanSizes
  class Mapper < Wukong::Streamer::RecordStreamer
    def process(code,model,time,country,j1,j2,j3, n1,n2,c1, venue,n3,n4, *sizes)
      yield [country, *sizes] if sizes.length == 13
    end
  end

  #
  # This uses an AccumulatingReducer directly.
  # It has the advantage of a minimal footprint.
  #
  class JeansAccumulatingReducer < Wukong::Streamer::AccumulatingReducer
    attr_accessor :sizes_sum

    # start the sum with 0 for each size
    def start! country, *first_sizes
      self.sizes_sum = first_sizes.map{ 0 }
    end
    # accumulate each size count into the sizes_sum
    def accumulate country, *sizes
      sizes.map!(&:to_i)
      self.sizes_sum = self.sizes_sum.zip(sizes).map{|sum, val| sum + val }
    end
    # emit [country, size_0_sum, size_1_sum, ...]
    def finalize
      yield [key, sizes_sum].flatten
    end
  end

  class JeansListReducer < Wukong::Streamer::ListReducer
    def finalize
      return if values.empty?
      sizes_sum = [0,0,0,0, 0,0,0,0, 0,0,0,0, 0]
      values.each do |country, *sizes|
        sizes.map!(&:to_i)
        sizes_sum = sizes_sum.zip(sizes).map{|sum, val| sum + val }
      end
      yield [key, *sizes_sum]
    end
  end
end

Wukong::Script.new(JeanSizes::Mapper, JeanSizes::JeansListReducer).run
