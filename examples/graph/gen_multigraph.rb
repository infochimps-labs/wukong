#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/../..'
require 'wukong'

class Edge < Struct.new(:src, :dest)
end

class MultiEdge < Struct.new(
    :src,           :dest,
    :a_follows_b,   :b_follows_a,
    :a_replies_b,   :b_replies_a,
    :a_favorites_b, :b_favorites_a
    )
end

module CombineEdges
  class Mapper < Wukong::Streamer::Base
    def process rsrc, src, dest, *_
      m = /^a_([a-z]+)_b/.match(rsrc) or return
      rel = m.captures.first
      yield ["%010d"%src.to_i,  "%010d"%dest.to_i, "a_#{rel}_b"]
      yield ["%010d"%dest.to_i, "%010d"%src.to_i, "b_#{rel}_a"]
    end
  end

  #
  #
  class Reducer < Wukong::Streamer::AccumulatingReducer
    attr_accessor :multi_edge
    def get_key src, dest, rel
      [src, dest]
    end
    def reset!
      self.multi_edge = MultiEdge.new
    end
    def accumulate src, dest, rel
      self.multi_edge[rel] ||= 0
      self.multi_edge[rel]  += 1
    end
    def finalize
      multi_edge.src, multi_edge.dest = key
      yield self.multi_edge
    end
  end

  class Script < Wukong::Script
    def default_options
      super.merge :sort_fields => 2
    end
  end
end

# Execute the script
CombineEdges::Script.new(
  CombineEdges::Mapper,
  CombineEdges::Reducer
  ).run
