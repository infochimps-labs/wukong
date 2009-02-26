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

module Gen1HoodEdges
  class Mapper < Wukong::Streamer::Base
    def process rsrc, src, dest, *data
      yield [ src,  :a_1hd, dest ]
      yield [ dest, :b_in,   src, *data]
      yield [ src,  :c_out, dest, *data]
    end
  end

  #
  #
  class Reducer < Wukong::Streamer::AccumulatingReducer
    attr_accessor :1hd, :ins, :outs
    def reset!
      self.1hd  = Set.new
      self.ins  = Set.new
    end
    def accumulate mid, pos, node, *node_data
      case pos.to_sym
      when :a_1hd
        self.1hd  << node
      when :b_in        
        next unless self.1hd.include?(node)
        self.ins << [node, node_data]
      when :c_out  
        next unless self.1hd.include?(node)
        ins.each do |inn, in_data|
          yield ['edge_2', inn, mid, node, in_data, node_data]
        end
      end
    end
    def finalize
    end
    def get_key mid, pos, node, *_
      [mid, pos, node]
    end
  end
  
  class Script
    def default_options
      super.merge :sort_fields => 2
    end
  end

end

# Execute the script
Wukong::Script.new(
  Gen1HoodEdges::Mapper,
  Gen1HoodEdges::Reducer
  ).run
