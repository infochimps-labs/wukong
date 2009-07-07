#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/../lib'
require 'wukong'

module WordCount
  class Mapper < Wukong::Streamer::LineStreamer
    #
    # Split a string into its constituent words.
    #
    # This is pretty simpleminded:
    # * downcase the word
    # * Split at any non-alphanumeric boundary, including '_'
    # * However, preserve the special cases of 's or 't at the end of a
    #   word.
    #
    #   tokenize("Jim's dawg won't hunt: dawg_hunt error #3007a4")
    #   # => ["jim's", "dawd", "won't", "hunt", "dawg", "hunt", "error", "3007a4"]
    #
    def tokenize str
      return [] unless str
      str = str.downcase;
      # kill off all punctuation except [stuff]'s or [stuff]'t
      # this includes hyphens (words are split)
      str = str.
        gsub(/[^a-zA-Z0-9\']+/, ' ').
        gsub(/(\w)\'([st])\b/, '\1!\2').gsub(/\'/, ' ').gsub(/!/, "'")
      # Busticate at whitespace
      words = str.strip.split(/\s+/)
      words.reject!{|w| w.blank? }
      words
    end

    #
    # Emit each word in each line.
    #
    def process line
      tokenize(line).each{|word| yield [word, 1] }
    end
  end

  #
  # Accumulate the sum record-by-record:
  #
  class Reducer0 < Wukong::Streamer::Base
    attr_accessor :key_count
    def process word, count
      @last_word ||= word
      if (@last_word == word)
        self.key_count += 1
      else
        yield [ @last_word, key_count ]
        @last_word = word
      end
    end
    def stream
      emit @last_word, key_count
    end
  end

  #
  # You can stack up all the values in a list then sum them at once:
  #
  require 'active_support/core_ext/enumerable'
  class Reducer1 < Wukong::Streamer::ListReducer
    def finalize
      yield [ key, values.map(&:last).map(&:to_i).sum ]
    end
  end

  #
  # A bit kinder to your memory manager: accumulate the sum record-by-record:
  #
  class Reducer2 < Wukong::Streamer::AccumulatingReducer
    attr_accessor :key_count
    def start!(*args)      self.key_count =  0 end
    def accumulate(*args)  self.key_count += 1 end
    def finalize
      yield [ key, key_count ]
    end
  end

  #
  # ... easiest of all, though: this is common enough that it's already included
  #
  require 'wukong/streamer/count_keys'
  class Reducer3 < Wukong::Streamer::CountKeys
  end

end

# Execute the script
Wukong::Script.new(
  WordCount::Mapper,
  WordCount::Reducer1
  ).run
