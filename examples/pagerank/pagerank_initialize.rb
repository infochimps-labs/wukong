#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/../../lib'
require 'wukong'
require 'wukong/streamer/set_reducer'

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

    def default_options
      super.merge :extra_args => ' -jobconf io.sort.record.percent=0.25 '
    end
  end

  #
  # Accumulate the dests list in memory, dump as a whole. Multiple edges between
  # any two nodes are permitted, and will accumulate pagerank according to the
  # edge's multiplicity.
  #
  class Reducer < Wukong::Streamer::ListReducer
    def accumulate src, dest
      self.values << dest
    end

    # Emit src, initial pagerank, and flattened dests list
    def finalize
      self.values = ['dummy'] if self.values.blank?
      yield [key, 1.0, self.values.to_a.join(",")]
    end
  end

  # Execute the script
  Script.new(nil, PageRank::Reducer).run
end



