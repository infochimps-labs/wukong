#!/usr/bin/env ruby
require 'rubygems'
require 'wukong'

# Run as (local mode)
#
#   ./examples/stupidly_simple_filter.rb --run=local input.tsv output.tsv
#
# for hadoop mode,
#
#   ./examples/stupidly_simple_filter.rb --run=hadoop input.tsv output.tsv
#
# For debugging, run
#
#   cat input.tsv | ./examples/stupidly_simple_filter.rb --map input.tsv | more
#

#
# A very simple mapper -- looks for a regex match in one field,
# and emits the whole record if the field matches
#
class GrepMapper < Wukong::Streamer::RecordStreamer

  MATCHER = %r{(ford|mercury|saab|mazda|isuzu)}

  #
  # Given a series of records like:
  #
  #    tweet  123456789   20100102030405     @frank: I'm having a bacon sandwich
  #    tweet  123456789   20100102030405     @jerry, I'm having your baby
  #
  # emits only the lines matching that regex
  #
  def process rsrc, id, timestamp, text, *rest
    yield [rsrc, id, timestamp, text, *rest] if line =~ MATCHER
  end
end

# Execute the script
Wukong::Script.new(
  GrepMapper,
  nil
  ).run
