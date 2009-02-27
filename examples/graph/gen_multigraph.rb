#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/../..'
require 'wukong'

class Edge < Struct.new(:src, :dest)
end

class MultiEdge < Struct.new(
    :src,           :dest,
    :a_follows_b,   :b_follows_a,
    :a_replies_b,   :b_replies_a,
    :a_atsigns_b,   :b_atsigns_a,
    :a_retweets_b,  :b_retweets_a,
    :a_favorites_b, :b_favorites_a
    )
end

module CombineEdges
  class Mapper < Wukong::Streamer::Base
    def process rsrc, src, dest, *_
      # note that a_retweets_b_id matches here
      m = /^a_([a-z]+)_b.*/.match(rsrc) or return
      rel = m.captures.first
      src = src.to_i ; dest = dest.to_i
      return if ((src == 0) || (dest == 0))
      yield ["%010d"%src,  "%010d"%dest, "a_#{rel}_b"]
      yield ["%010d"%dest, "%010d"%src,  "b_#{rel}_a"]
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
