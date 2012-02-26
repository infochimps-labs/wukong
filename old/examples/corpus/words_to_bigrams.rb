#!/usr/bin/env ruby
require 'rubygems'
require 'wukong/script'

#
# Bigram counts
#
# head -n 100 /usr/share/dict/words | ./examples/corpus/words_to_bigrams.rb  | sort |  /tmp/words_to_bigrams.rb
#


#
# Kludge to work in Elastic map reduce:
#
# If your script is ./examples/corpus/words_to_bigrams.rb, make symlinks
# to it from ./examples/corpus/words_to_bigrams__map.rb and
# ./examples/corpus/words_to_bigrams__reduce.rb
#
if $0 =~ /__(map|reduce)\.rb$/
  Settings[$1.to_sym] = true
end


#
# given one word per line
# emits all successive pairs of characters in that word
# eg 'boooo-urns' yields
#   bo oo oo oo o- -u ur rn ns
#
class WordNGrams < Wukong::Streamer::Base
  def process word
    word[0..-2].chars.zip(word[1..-1].chars).each do |ngram_2|
      yield ngram_2.join('')
    end
  end
end

#
# number of unique keys in a row
#
class KeyCountStreamer < Wukong::Streamer::AccumulatingReducer
  def start! *args
    @count = 0
  end
  def accumulate *args
    @count += 1
  end
  def finalize
    yield [key, @count]
  end
end

Wukong::Script.new(WordNGrams, KeyCountStreamer).run
