#!/usr/bin/env ruby
require 'rubygems'
require 'wukong/script'

#
# Given an adjacency pairs (from \t to) representation of a directed graph:
#
#    1     2
#    1     7
#    2     7
#    2     9
#    7     2
#
# It produces an "adjacency list":http://en.wikipedia.org/wiki/Adjacency_list representation:
#
#    1  >   2   7
#    2  >   7   9
#    7  >   2
#    9  >
#
# and
#
#    1  <
#    2  <   1   7
#    7  <   1   2
#    9  <   2
#
# (each column is tab-separated in the actual output)
#
#
#
module Gen1HoodEdges
  class Mapper < Wukong::Streamer::Base
    def process rsrc, src, dest, *_
      src = src.to_i ; dest = dest.to_i
      yield [ src,  '>', dest ]
      yield [ dest, '<', src  ]
    end
  end

  #
  # Accumulate links onto single line.
  #
  # The reduce key is the target node and direction; we just stream through all
  # pairs for each target node and output its neighbor nodes on the same line.
  #
  # To control memory usage, we will print directly to the output (and not run
  # through the Emitter)
  #
  class Reducer < Wukong::Streamer::AccumulatingReducer
    # clear the list of incoming paths
    def start! target, dir, *args
      print target + "\t" + dir  # start line with target and list type
    end
    def accumulate target, dir, neighbor
      print "\t" + neighbor      # append neighbor to output, same line
    end
    def finalize
      puts ''                    # start new line
    end
  end

  class Script < Wukong::Script
    def default_options
      super.merge :sort_fields => 1, :partition_fields => 1
    end
  end
end

# Execute the script
Gen1HoodEdges::Script.new(
  Gen1HoodEdges::Mapper,
  Gen1HoodEdges::Reducer
  ).run
