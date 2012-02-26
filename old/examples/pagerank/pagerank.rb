#!/usr/bin/env ruby
require 'rubygems'
require 'wukong/script'

module PageRank
  #
  # Damping factor (prob. of a 'random' jump)
  # 0.85 works well in practice. See http://en.wikipedia.org/wiki/Pagerank
  #
  DAMPING_FACTOR = 0.85

  # Each user's line looks like
  #   user_a    pagerank        id1,id2,...,idN
  # we need to disperse this user's pagerank to each of id1..idN, and
  # rendezvous the list of outbound links at user_a's reducer as well.
  module Iterating
    class PagerankMapper < Wukong::Streamer::Base
      #
      # Send pagerank to each page, and send the dests list back to self
      #
      def process src, pagerank, dests_str, &block
        # This lets us use Pig to generate the input
        dests_str = dests_str.gsub(/[\(\{\}\)]/, '')
        dests     = dests_str.split(",")
        yield_pagerank_shares src, pagerank, dests, &block
        yield_own_dest_list   src, dests_str,       &block
      end

      # Take the source node's pagerank and distribute it among all the out-nodes
      def yield_pagerank_shares src, pagerank, dests
        pagerank_share = pagerank.to_f / dests.length
        dests.each do |dest|
          yield [dest, 'p', pagerank_share]
        end
      end

      # Dispatch this user's out-node list to rendezvous with itself.
      def yield_own_dest_list src, dests_str
        yield [src, 'd', dests_str]
      end
    end

    class PagerankReducer < Wukong::Streamer::AccumulatingReducer
      attr_accessor :node_id, :pagerank, :dests_str
      # Begin reduction with 0 accumulated pagerank and no dests as yet
      def start! node_id, *args
        self.node_id   = node_id
        self.pagerank  = 0.0
        self.dests_str = nil
      end
      # We'll receive fractional pagerank from all incoming edges,
      # and the destination list from this node's map stage
      def accumulate node_id, what, val
        case what
        when 'p' then self.pagerank += val.to_f
        when 'd' then self.dests_str = val
        else     raise "Don't know how to accumulate #{[node_id, what, val].inspect}"
        end
      end
      # To finalize, dump the damped pagerank and dest list
      # in a form that can be fed back into this script
      def finalize
        damped_pagerank = (self.pagerank * DAMPING_FACTOR) + (1 - DAMPING_FACTOR)
        self.dests_str = 'dummy' if self.dests_str.blank?
        yield [node_id, damped_pagerank, dests_str]
      end
    end

    Wukong.run(PagerankMapper, PagerankReducer,
      :extra_args => ' -jobconf io.sort.record.percent=0.25 ')
  end
end
