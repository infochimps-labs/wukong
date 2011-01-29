#!/usr/bin/env ruby
require 'rubygems'
require 'wukong'

#
# Takes any number of flavors of directed edge with the form
#
#   a_relatesto_b src_id dest_id [optional fields]
#
# and prepares a combined adjacency list.  You need to supply a model named
# "MultiEdge" with members for each edge type.
#
# For instance, suppose you have a social network with edges like
#
#   a_follows_b   user_a_id  user_b_id
#   a_messages_b  user_a_id  user_b_id  message_id date
#   a_favorites_b user_a_id  user_b_id  message_id date
#
# Your MultiEdge class might look like
#
#   class MultiEdge < Struct(
#     :src, :dest,
#     :a_follows_b,   :b_follows_a,
#     :a_messages_b,   :b_messages_a,
#     :a_favorites_b, :b_favorites_a
#     )
#   end
#
# The row for a user pair who follows each other; with user_a #24601 messaging b
# 57 times and favoriting 5 of user_b's messages; and user_b #8675309 messaging
# 62 times and favoriting none, will emerge as (tab separated, with [blank]
# indicating there is no text in that slot):
#
#   ...
#   24601       8675309 1       1       57      62      5       [blank]
#   ...
#
module GenMultiEdge
  #
  # Emit each relation as
  #
  #   src       dest    rel
  #
  # Canonicalizes the src and dest ids to 10-character, zero-padded strings.
  # (Ten chars fits a 32-bit up-to-4-billion-and-change unsigned integer.)
  # Discards all the ancillary crap except +src+, +dest+ and +rel+
  #
  class Mapper < Wukong::Streamer::Base
    def process rsrc, src, dest, *_
      # note that a_retweets_b_id matches here
      m = /^a_([a-z]+)_b.*/.match(rsrc) or return
      rel = m.captures.first
      src = src.to_i ; dest = dest.to_i
      return if ((src == 0) || (dest == 0))
      yield [src,  dest, "a_#{rel}_b"]
      yield [dest, src,  "b_#{rel}_a"]
    end
  end

  #
  # Aggregate all sightings of relations for each pair into
  # a single combined
  #
  # Note that [a,b] and [b,a] /each/ have a listing, with the a->b and b<-a
  # relations repeated for each.  That is, if there is an "a_messages_b"
  # relation, you'll have edges
  #
  #    x        y       ...     a_messages_b(x,y)       b_messages_a(y,x)  ...
  #    y        x       ...     a_messages_b(y,x)       b_messages_a(x,y)  ...
  #
  #
  class Reducer < Wukong::Streamer::AccumulatingReducer
    attr_accessor :multi_edge
    def get_key src, dest, rel
      [src, dest]
    end
    def start! *args
      self.multi_edge = MultiEdge.new
    end
    def accumulate src, dest, rel
      self.multi_edge[rel] ||= 0
      self.multi_edge[rel]  += 1
    end
    def finalize
      multi_edge.src, multi_edge.dest = key
      yield self.multi_edge
    end
  end
end

Edge = TypedStruct.new(
  [:src,              Integer],
  [:dest,             Integer]
  )

MultiEdge = TypedStruct.new(
  [:src,              Integer],
  [:dest,             Integer],
  [:a_follows_b,      Integer],
  [:b_follows_a,      Integer],
  [:a_replies_b,      Integer],
  [:b_replies_a,      Integer],
  [:a_atsigns_b,      Integer],
  [:b_atsigns_a,      Integer],
  [:a_retweets_b,     Integer],
  [:b_retweets_a,     Integer],
  [:a_favorites_b,    Integer],
  [:b_favorites_a,    Integer]
  )

# Execute the script
Script.new(Mapper, Reducer, :sort_fields => 2).run
