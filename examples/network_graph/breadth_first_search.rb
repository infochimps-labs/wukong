#!/usr/bin/env ruby
require 'rubygems'
require 'wukong/script'

#
# Use this script to do a Breadth-First Search (BFS) of a graph.
#
# Usage:
#   ./make_paths --head=[path_in_key] --tail=[path_out_key] --out_rsrc=[combined_path_key]
#
# For example, given an edge list in the file '1path.tsv' that looks like
#   1path       n1      n2
#   1path       n1      n3
#   ... and so forth ...
# you can run
#   for t in 1 2 3 4 5 6 7 8 9 ; do next=$((t+1)) ; time cat 1path.tsv "${t}path.tsv" | ./make_paths.rb --map --head="1path"  --tail="${t}path" | sort -u | ./make_paths.rb --reduce --out_rsrc="${next}path" | sort -u > "${next}path.tsv" ; done
# to do a 9-deep breadth-first search.
#
module Gen1HoodEdges
  class Mapper < Wukong::Streamer::RecordStreamer
    def initialize
      @head = Settings[:head]
      @tail = Settings[:tail]
    end
    def process rsrc, *nodes
      yield [ nodes.last,  'i', nodes[0..-2] ] if (rsrc == self.head)
      yield [ nodes.first, 'o', nodes[1..-1] ] if (rsrc == self.tail)
    end
  end

  #
  # Accumulate ( !!in memory!!) all inbound links onto middle node
  #
  # Then for each outbound link, loop over those inbound links and emit the
  # triple (in, mid,out)
  #
  class Reducer < Wukong::Streamer::AccumulatingReducer
    attr_accessor :paths_in, :out_rsrc
    def initialize
      self.out_rsrc = Settings[:out_rsrc]
    end
    # clear the list of incoming paths
    def start! *args
      self.paths_in  = []
    end
    def accumulate mid, dir, *nodes
      case dir
      when 'i'
        self.paths_in << nodes
        if (self.paths_in.length % 1000 == 0) && (self.paths_in.length > 10000)
          $stderr.puts ["Accumulating:", mid, self.paths_in.length].join("\t")
        end
      when 'o'
        paths_in.each do |path_in|
          yield [self.out_rsrc, path_in, mid, *nodes]
        end
      end
    end
    def finalize
    end
    def get_key mid, *_
      mid
    end
  end
end

# Execute the script
Wukong.run(
  Gen1HoodEdges::Mapper,
  Gen1HoodEdges::Reducer,
   :sort_fields => 2, :partition_fields => 1
  )
