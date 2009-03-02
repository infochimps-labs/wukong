#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/..'
require 'wukong'

module RankAndBin
  class CutMapper
    def process

    end
  end

  module PreprocessPipeStreamer
    #
    #
    # You must provide the preprocess_pipe_command method, giving
    # a shell command to run the input through.
    #
    # For an example, see RankAndBinReducer
    #
    def stream
      `#{preprocess_pipe_command}`.readlines do |line|
        item = itemize(line) ; next if item.blank?
        process(*item)
      end
    end
  end

  #
  # For each record, appends a
  # 
  # * numbering, from 0..(n-1).  Each element gets a distinct numbering based on
  #   the order seen at the reducer; elements with identical keys might have
  #   different numbering on different runs.
  #
  # * rank, a number within 1..n giving the "place" of each value. Each element
  #   receives a successive (and thus unique) numbering, but all elements with
  #   the same key share the same rank. The first element for a given rank has
  #
  #     (rank == numbering + 1)
  #
  # * bin, a number assigning keys by rank into a smaller number of groups.  You
  #   must supply command line arguments
  #
  #     --bins=[number] --total_count=[number]
  #   
  #   giving the number of groups and predicting in advance the total number of
  #   records. (Or override the bin assignment method to use your own damn
  #   strategy).
  #
  # If your data looked (in order) as follows, and 4 bins were requested:
  #
  #   data:       1   1   1 2.3   7  69  79  79  80  81  81
  #   numbering:  0   1   2   3   4   5   6   7   8   9  10
  #   rank:       1   1   1   4   5   6   7   7   9  10  10
  #   4-bin:      1   1   1   2   2   3   3   3   4   4   4
  #
  # If instead 100 bins were requested, 
  #
  #   data:       1   1   1 2.3   7  69  79  79  80  81  81
  #   numbering:  0   1   2   3   4   5   6   7   8   9  10
  #   rank:       1   1   1   4   5   6   7   7   9  10  10
  #   100-bin:    1   1   1  28  37  46  55  55  73  82  91
  #
  # Note most of the bins are empty, and that the 
  #
  # --------------------------------------------------------------------------
  #
  # Note that in this implementation you have to set @:reduce_tasks => 1@ in
  # your Script's Script#default_options 
  # 
  # It would surely be best to use a total sort and supply each reducer with the
  # initial rank of its run.
  #
  class RankAndBinReducer < Wukong::Streamer::Base
    def initialize options
      super options
      configure_bins! options
      @last_key  = nil
      @numbering = 0
      @rank      = 1
    end

    # ===========================================================================
    #
    #  
    #

    #
    # The value to rank by
    #
    def get_key *args
      args.first
    end

    # 
    # The ranking is the "place" of each value: each element receives a
    # successive (and thus unique) numbering, but all elements with the same key
    # share the same rank. The first element for a given rank has
    #
    #   (rank == numbering + 1)
    #
    # If your data looked (in order) as follows, and 4 bins were requested:
    #
    #   data:       1   1   1 2.3   7  69  79  79  80  81  81
    #   numbering:  0   1   2   3   4   5   6   7   8   9  10
    #   rank:       1   1   1   4   5   6   7   7   9  10  10
    #   4-bin:      1   1   1   2   2   3   3   3   4   4   4
    #
    #
    def get_rank key
      if @last_key != key
        @rank       = @numbering + 1
        @last_key   = key
      end
      @rank
    end

    #
    # Set the bin from the value and the current rank
    #
    def get_bin rank
      ((rank-0.5) / bin_size ).round
    end

    #
    # Return the numbering, rank and bin for the given key
    #
    def get_order_params key
      numbering   = @numbering # use un-incremented value
      rank        = get_rank key
      bin         = get_bin  rank      
      @numbering += 1
      [numbering, rank, bin]
    end

    attr_accessor :bin_size
    def configure_bins! options
      case
      when options[:bins]
        total_count = options[:total_count].to_f
        bins        = options[:bins].to_i
        unless total_count && (total_count != 0) then raise "To set the bin (%ile) size using --bins, we need to know the total count in advance. Please supply the total_count option." end
        self.bin_size = (total_count / bins)
        $stderr.puts "Splitting %s records into %s bins of size %f. First element gets bin %d, last gets bin %d, median gets bin %d/%d" %
          [total_count, bins, bin_size, get_bin(1), get_bin(total_count), get_bin(((total_count+1)/2.0).floor), get_bin(((total_count+1)/2.0).ceil)]
      else
        raise "Please specify a number of --bins= and a --total_count= or your own strategy to bin the ranked items."
      end
    end

    #
    # Prepare 
    #
    def format_binned_record fields, numbering, rank, bin
      fields.to_flat + ["%10d"%numbering, "%10d"%rank, "%7d"%bin]
    end

    def process *fields
      numbering, rank, bin = get_order_params(get_key(*fields))
      yield format_binned_record(fields, numbering, rank, bin)
    end

  end
  
  class Script < Wukong::Script
    def default_options
      super.merge :reduce_tasks => 1
    end
  end
  Script.new(nil, RankAndBinReducer).run
end
