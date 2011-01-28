#!/usr/bin/env ruby
require 'rubygems'
require 'cassandra'
require 'wukong'
require 'wukong/encoding'
require 'wukong/keystore/cassandra_conditional_outputter'

#
# Usage:
#   echo -e "bob has boobs ha ha ha" | ./examples/keystore/conditional_outputter_example.rb  --map
#

CASSANDRA_KEYSPACE = 'CorpusAnalysis'

#
# This demonstrates the CassandraConditionalOutputter module.
#
# CassandraConditionalOutputter uses and a cassandra key-value store to
# track unique IDs and prevent output of any record already present in the
# database.
#
# For this example, it takes an input stream, generates all letter pairs for
# each line, and emits
#
#
class LetterPairMapper <  Wukong::Streamer::LineStreamer
  include CassandraConditionalOutputter

  #
  # A unique key for the given record. If an object with
  # that key has been seen, it won't be re-emitted.
  #
  # In this example, we'll just encode the letter pair
  #
  def conditional_output_key record
    record.to_s.wukong_encode(:url)
  end

  #
  # Emit each letter pair in the line.
  # the CassandraConditionalOutputter will swallow all duplicate lines.
  #
  def process line, &block
    letter_pairs(line).each do |pair|
      yield(pair)
    end
  end

  # turn a string into the pairs of adjacent letters
  #
  # @example
  #   letter_pairs('abracadabra')
  #   # => ['ab', 'br',
  def letter_pairs str, &block
    chars = str.chars.to_a
    chars[0..-2].zip(chars[1..-1]).map(&:join)
  end

  # Clear the entire cached keys column at the end of the run.
  #
  # You almost certainly don't want to do this in a real script.
  #
  def after_stream
    $stderr.puts 'Clearing conditional_output_key cache...'
    @key_cache.clear_column_family!(conditional_output_key_column)
  end
end

# Execute the script
Wukong::Script.new( LetterPairMapper, nil ).run
