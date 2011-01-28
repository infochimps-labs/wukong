#!/usr/bin/env ruby
require 'rubygems'
require 'wukong/script'

module WordCount
  class Mapper < Wukong::Streamer::LineStreamer
    #
    # Split a string into its constituent words.
    #
    # This is pretty simpleminded:
    # * downcase the word
    # * Split at any non-alphanumeric boundary, including '_'
    # * However, preserve the special cases of 's, 'd or 't at the end of a
    #   word.
    #
    #   tokenize("Ability is a poor man's wealth #johnwoodenquote")
    #   # => ["ability", "is", "a", "poor", "man's", "wealth", "johnwoodenquote"]
    #
    def tokenize str
      return [] if str.blank?
      str = str.downcase;
      # kill off all punctuation except [stuff]'s or [stuff]'t
      # this includes hyphens (words are split)
      str = str.
        gsub(/[^a-zA-Z0-9\']+/, ' ').
        gsub(/(\w)\'([std])\b/, '\1!\2').gsub(/\'/, ' ').gsub(/!/, "'")
      # Busticate at whitespace
      words = str.split(/\s+/)
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
  # You can stack up all the values in a list then sum them at once.
  #
  # This isn't good style, as it means the whole list is held in memory
  #
  class Reducer1 < Wukong::Streamer::ListReducer
    def finalize
      yield [ key, values.map(&:last).map(&:to_i).inject(0){|x,tot| x+tot } ]
    end
  end

  #
  # A bit kinder to your memory manager: accumulate the sum record-by-record:
  #
  class Reducer2 < Wukong::Streamer::AccumulatingReducer
    def start!(*args)      @key_count =  0 end
    def accumulate(*args)  @key_count += 1 end
    def finalize
      yield [ key, @key_count ]
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
Wukong.run(
  WordCount::Mapper,
  WordCount::Reducer
  )
