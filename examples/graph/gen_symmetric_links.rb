#!/usr/bin/env ruby
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
