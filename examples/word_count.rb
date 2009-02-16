#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/..'
require 'wukong'

module WordCount
  class Mapper < Wukong::Streamer::Base
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
  # You can stack up all the values in a list then sum them at once:
  #
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
    def reset!()           self.key_count =  0 end
    def accumulate(*args)  self.key_count += 1 end
    def finalize
      yield [ key, key_count ]
    end
  end

  #
  # ... easiest of all, though: this is common enough that it's already included
  #
  class Reducer3 < Wukong::Streamer::CountKeys
  end

end

# Execute the script
Wukong::Script.new(
  WordCount::Mapper,
  WordCount::Reducer3,
  ).run
