module Wukong
  module Streamer

    #
    # Bin and order a partitioned subset of keys
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
    # Note that in this implementation each reducer numbers its own subset of
    # elements from 1..total_count. If you want to number your whole dataset,
    # you'll have to set @:reduce_tasks => 1@ in your Script's
    # Script#default_options.
    #
    # You might feel a bit better about yourself if you can bin several fields
    # (or subsets) at once. The :partition_fields option to Wukong::Script
    # (which requests a KeyFieldBasedPartitioner) can be used to route different
    # subsets to (possibly) distinct reducers.
    #
    # See the [examples/rank_and_bin_fields.rb] example script for an
    # implementation of this. (And note the thing you have to do in case one
    # reducer sees multiple partitions).
    #
    # It would surely be best to use a total sort and supply each reducer with the
    # initial rank of its run.
    #
    class RankAndBinReducer < Wukong::Streamer::Base
      attr_accessor :bin_size
      def initialize options
        super options
        configure_bins! options
        reset_order_params!
      end

      # ===========================================================================
      #
      # Order parameters (numbering, bin and rank)
      #

      #
      # Key used to assign ranking -- elements with identical keys have identical
      # rank.
      #
      def get_key *args
        args.first
      end

      def reset_order_params!
        @last_key  = nil
        @numbering = 0
        @rank      = 1
      end

      #
      # The ranking is the "place" of each value: each element receives a
      # successive (and thus unique) numbering, but all elements with the same key
      # share the same rank. The first element for a given rank has
      #
      #   (rank == numbering + 1)
      #
      def get_rank key
        if @last_key != key
          @rank       = @numbering + 1
          @last_key   = key
        end
        @rank
      end

      #
      # Set the bin from the current rank
      # elements with identical keys land in identical bins.
      #
      def get_bin rank
        ((rank-0.5) / bin_size ).floor + 1
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

      def configure_bins! options
        case
        when options[:bins]
          total_count = options[:total_count].to_f
          bins        = options[:bins].to_i
          unless total_count && (total_count != 0) then raise "To set the bin (%ile) size using --bins, we need to know the total count in advance. Please supply the total_count option." end
          self.bin_size = (total_count / bins)
          # $stderr.puts "Splitting %s records into %s bins of size %f. First element gets bin %d, last gets bin %d, median gets bin %d/%d" %
          #   [total_count, bins, bin_size, get_bin(1), get_bin(total_count), get_bin(((total_count+1)/2.0).floor), get_bin(((total_count+1)/2.0).ceil)]
        else
          raise "Please specify a number of --bins= and a --total_count= or your own strategy to bin the ranked items."
        end
      end

      def process *fields
        numbering, rank, bin = get_order_params(get_key(*fields))
        yield fields.to_flat + [numbering, rank, bin]
      end
    end

  end
end
