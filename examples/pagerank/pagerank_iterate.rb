#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'set'
require 'pathname'
require 'wukong'

#
# Damping factor (prob. of a 'random' jump)
# 0.85 works well in practice. See http://en.wikipedia.org/wiki/Pagerank
#
DAMPING_FACTOR = 0.85
N_ITERS = 10

module PageRank
  class Mapper < Wukong::Streamer::Base
    #
    def recordize line
      src, pagerank, dests, *rest = super(line)
      dests = dests.strip.split(',') if dests
      pagerank   = pagerank.to_f
      [src, pagerank, dests, *rest]
    end

    # distribute pagerank among outbound links
    def emit_pagerank_shares src, pagerank, dests
      outdegree      = dests.length
      pagerank_share = pagerank / outdegree
      dests.each do |dest|
        yield [dest, 'pr_share', pagerank_share]
      end
    end

    # we need to dispatch the list of destination ids
    def emit_dest_ids src, dests
      yield [src, 'dests', dests.join(',')]
    end

    #
    # Launch each relation towards its stakeholders,
    # who will aggregate them in the +reduce+ phase
    #
    def process src, pagerank, dests, *rest, &block
      warn "Missing dests in line #{line}" if dests.nil?
      warn "Zero pagerank in line #{line}" if pagerank == 0.0
      # Recycle the list of destination ids
      emit_dest_ids src, dests, &block
      # Emit pagerank shares
      emit_pagerank_shares src, pagerank, dests, &block
    end
  end

  #
  # You can stack up all the values in a list then sum them at once:
  #
  class Reducer < Wukong::Streamer::AccumulatingReducer
    attr_accessor :pagerank, :dests

    #
    # start with an empty destinations list and
    # no incoming pagerank shares
    #
    def start! *args
      self.pagerank = 0.0
      self.dests    = nil
    end

    #
    # accumulate both the passed-through list of destination links, and the
    # pagerank share from every incoming link.
    #
    def accumulate key, what, val
      case
      when what == 'pr_share'
        # w00t we got some pagerank love
        self.pagerank += val.to_f
      when what == 'dests'
        # here's the list of destination ids
        self.dests = val
      else raise "Bad what '#{what}': #{[key, what, vals].inspect}"
      end
    end

    #
    # Once we've collected our outbound links and all inbound pagerank shares,
    # emit the new damped pagerank value
    #
    def finalize
      damped_pagerank = (pagerank * DAMPING_FACTOR) + (1 - DAMPING_FACTOR)
      self.dests = 'dummy' if self.dests.blank?
      yield [key, damped_pagerank, dests]
    end
  end
end

# Execute the script
Wukong::Script.new(
  PageRank::Mapper,
  PageRank::Reducer
  ).run


