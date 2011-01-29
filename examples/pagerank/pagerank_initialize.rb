#!/usr/bin/env ruby
require 'rubygems'
require 'wukong/script'
require 'wukong/streamer/list_reducer'

module PageRank
  class Script < Wukong::Script
    #
    # Input format is
    #
    #   rsrc    src_id  dest_id  [... junk ...]
    #
    # All we want from the line are its src and dest IDs.
    #
    def map_command
      %Q{/usr/bin/cut -d"\t" -f2,3}
    end
  end

  #
  # Accumulate the dests list in memory, dump as a whole. Multiple edges between
  # any two nodes are permitted, and will accumulate pagerank according to the
  # edge's multiplicity.
  #
  class Reducer < Wukong::Streamer::ListReducer
    def accumulate src, dest
      @values << dest
    end

    # Emit src, initial pagerank, and flattened dests list
    def finalize
      @values = ['dummy'] if @values.blank?
      yield [key, 1.0, @values.to_a.join(",")]
    end
  end

  # Execute the script
  Script.new(nil, PageRank::Reducer, :io_sort_record_percent => 0.25).run
end



