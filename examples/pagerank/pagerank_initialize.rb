#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'set'
require 'pathname'


module PageRank
  class Mapper < Wukong::Streamer::Base

    #
    # All we want from the line are its src and dest IDs
    #
    def recordize line
      fields = super(line)
      src, dest, *_ = fields
    end
    
    #
    # Launch each relation towards each of its stakeholders,
    # who will aggregate them in the +reduce+ phase
    #
    def process src, dest
        yield [src, dest]
      end
    end
  end

  #
  # You can stack up all the values in a list then sum them at once:
  #
  class Reducer < Wukong::Streamer::AccumulatingReducer
    attr_accessor :dests
    #
    def reset!
      self.dests = []
    end
    
    # 
    def accumulate src, dest
      dests << dest
    end
    
    # emit relationship for heretrix pagerank code
    def finalize
      dests = ['dummy'] if dests.blank?
      yield [src, 1.0, dests.join(",")]
    end
  end
end

# Execute the script
Wukong::Script.new(
  PageRank::Mapper,
  PageRank::Reducer,
  ).run


