#!/usr/bin/env ruby
require 'rubygems'
$: << File.dirname(__FILE__)+'/../../lib'
require 'wukong'

class Edge < Struct.new(:src, :dest)
end

class ASymmetricB < Edge
end

module Wukong::Streamer
  class EdgeStreamer < Wukong::Streamer::Base
    def recordize line
      rsrc, src, dest, *_ = super(line)
      [ASymmetricB.new(src.to_i, dest.to_i)]
    end
  end
end

#
# Find symmetric links
#
# Takes adjacency list for a directed graph and emits only edges where
#   A->B and B->A
#
# The output will list each such symmetric edge exactly once as
#    a_symmetric_b   node1    node2
# where node1 is lexicographically less than node2.
#
module FindSymmetricLinks

  class Mapper < Wukong::Streamer::EdgeStreamer
    def process edge
      yield edge.to_flat(false)
      yield ASymmetricB.new(edge.dest, edge.src).to_flat(false)
    end
  end

  #
  #
  class Reducer < Wukong::Streamer::Base
    def stream
      %x{/usr/bin/uniq -c}.split("\n").each do |line|
        key_count, rsrc, src, dest, data = line.chomp.strip.split(/\s+/, 4)
        next unless key_count.to_i == 2
        next unless src.to_i < dest.to_i
        emit [src, dest, data].compact
      end
    end
  end

  class Script < Wukong::Script
    def default_options
      super.merge :sort_fields => 3
    end
  end
end

# Execute the script
Wukong::Script.new(
  FindSymmetricLinks::Mapper,
  FindSymmetricLinks::Reducer
  ).run
