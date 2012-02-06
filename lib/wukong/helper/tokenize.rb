require File.expand_path('stopwords', File.dirname(__FILE__))
module Wukong
  module Helper

    module Tokenize
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
      def self.tokenize str
        return [] if str.blank?
        str = str.downcase;
        # kill off all punctuation except [stuff]'s or [stuff]'t
        # this includes hyphens (words are split)
        str = str.
          gsub(/[^a-zA-Z0-9\']+/, ' ').
          gsub(/(\w)\'([stdm]|re|ve|ll)\b/, '\1!\2').gsub(/\'/, ' ').gsub(/!/, "'")
        # Busticate at whitespace
        words = str.split(/\s+/)
        words.reject!{|w| w.length < 3 ||  Wukong::Corpus::STOPWORDS_3.include?(w) }
        words
      end

    end

  end
end
