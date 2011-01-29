#!/usr/bin/env ruby
require 'rubygems'
require 'wukong/script'

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

class Mapper < LineStreamer
  include Filter
  MATCHER = %r{(ford|mercury|saab|mazda|isuzu)}

  #
  # A very simple mapper -- looks for a regex match in one field,
  # and emits the whole record if the field matches
  #
  #
  # Given a series of records like:
  #
  #    tweet  123456789   20100102030405     @frank: I'm having a bacon sandwich
  #    tweet  123456789   20100102030405     @jerry, I'm having your baby
  #
  # emits only the lines matching that regex
  #
  def emit? line
    MATCHER.match line
  end
end

# Execute the script
Wukong.run(Mapper)
