#!/usr/bin/env ruby
# run like so:
# $> ruby normalize.rb --run=local --input data/sizes --output data/normalized_sizes
require 'rubygems'
require 'wukong'
require 'active_support/core_ext/enumerable' # for array#sum

module Normalize
  class Mapper < Wukong::Streamer::RecordStreamer
    def process(country, *sizes)
      sizes.map!(&:to_i)
      sum = sizes.sum.to_f
      normalized = sizes.map{|x| 100 * x/sum }
      s = normalized.join(",")
      yield [country, s]
    end
  end
end

Wukong::Script.new(Normalize::Mapper, nil).run
