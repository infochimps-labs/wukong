#!/usr/bin/env ruby
require 'rubygems'
require 'wukong/script'

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
    def process rsrc, src, dest
      # next if (src.to_i == 0) || (dest.to_i == 0)
      yield [ dest, 'i', src ]
      yield [ src,  'o', dest]
    end
  end

  #
  # Accumulate ( !!in memory!!) all inbound links onto middle node
  #
  # Then for each outbound link, loop over those inbound links and emit the
  # triple (in, mid,out)
  #
  class Reducer < Wukong::Streamer::AccumulatingReducer
    attr_accessor :ins
    def start! *args
      self.ins  = []
    end
    def accumulate mid, dir, node
      case dir
      when 'i'
        self.ins << node
        if (self.ins.length % 1000 == 0) && (self.ins.length > 10000)
          $stderr.puts ["Accumulating:", mid, self.ins.length].join("\t")
        end
      when 'o'
        ins.each do |inn|
          yield ['path_2', inn, mid, node]
        end
      end
    end
    def finalize
    end
    def get_key mid, *_
      mid
    end
  end

  class Script < Wukong::Script
    def default_options
      super.merge :sort_fields => 2, :partition_fields => 1
    end
  end

end

# Execute the script
Gen1HoodEdges::Script.new(
  Gen1HoodEdges::Mapper,
  Gen1HoodEdges::Reducer
  ).run
