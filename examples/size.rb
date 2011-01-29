#!/usr/bin/env ruby
require 'rubygems'
require 'wukong/script'

module Size
  #
  # Feed the entire dataset through wc and sum the results
  #
  class Script < Wukong::Script
    #
    # Don't implement a wukong script to do something if there's a unix command
    # that does it faster: just override map_command or reduce_command in your
    # subclass of Wukong::Script to return the complete command line
    #
    def map_command
      '/usr/bin/wc'
    end

    # Make all records go to one reducer
    def default_options
      super.merge :reduce_tasks => 1
    end
  end

  #
  # Sums the numeric value of each column in its input
  #
  class Reducer < Wukong::Streamer::Base
    attr_accessor :sums

    #
    # The unix +wc+ command uses whitespace, not tabs, so we'll recordize
    # accordingly.
    #
    def recordize line
      line.strip.split(/\s+/)
    end

    #
    # add each corresponding column in the input
    #
    def process *vals
      self.sums = vals.zip( sums || [] ).map{|val,sum| val.to_i + sum.to_i }
    end

    #
    # run through the whole reduction input and then output the total
    #
    def stream *args
      super *args
      emit sums
    end
  end
end

# Execute the script
Size::Script.new(
  nil,
  Size::Reducer,
  :reduce_tasks => 1
  ).run
