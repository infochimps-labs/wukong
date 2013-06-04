#!/usr/bin/env ruby

require_relative '../../examples_helper'
require 'wu/text/word_list'
require 'digest/md5'
require 'digest/sha1'

MAGI = Pathname.of(:data, 'text/gift_of_the_magi.txt').read.
  split(/\n\n+/).
  map{|para| para.gsub!(/\n/, ' '); para.gsub!(/(mrs|mr|mne)\./i, '\1'); para.split(/\.\s+/) }.
  flatten.
  each{|str|
  str.gsub!(/\b'\b/, "");
  str.gsub!(/\W+/, " ");
  str.downcase! ;
  str.strip!
}

# magi.each{|para| p para }
# exit

SCRABBLE_VALUES = {
  "a" => 1, "b" => 3, "c" => 3, "d" => 2, "e" => 1, "f" => 4, "g" => 2,
  "h" => 4, "i" => 1, "j" => 8, "k" => 5, "l" => 1, "m" => 3, "n" => 1,
  "o" => 1, "p" => 3, "q" =>10, "r" => 1, "s" => 1, "t" => 1, "u" => 1,
  "v" => 4, "w" => 4, "x" => 8, "y" => 4, "z" =>10,
}

CAESAR_VALUES = ('a'..'z').hashify{|char| 1 + char.ord - 'a'.ord }

module StupidHashes
  extend self

  TWL_WORDS = Wu::Text::WordList.from_file(:twl)
  SIMPLE_STOPWORDS = Wu::Text::Stopwords.new(remove_apos: true)

  def scrabble_hash(word)
    - word.chars.map{|ch| SCRABBLE_VALUES[ch] || 0 }.sum.to_f / word.length
  end

  def caesar(word)
    - word.chars.map{|ch| CAESAR_VALUES[ch]   || 0 }.sum.to_f / word.length
  end

  def length(word)
    - word.length
  end

  def bsd_position(word)
    TWL_WORDS.index(word) || 1_000_000_000
  end

  def md5(word)
    Digest::MD5.hexdigest(word)[-8..-1].to_i(16)
  end

  def sha1(word)
    Digest::SHA1.hexdigest(word)[-8..-1].to_i(16)
  end

  def minhash(words, hash_name)
    func = method(hash_name)
    words.map{|word| [func.(word), word] }.sort
  end

end

MAGI.map do |line|
  words = line.split.sort.uniq
  # StupidHashes::SIMPLE_STOPWORDS.remove!(words)
  next if words.blank?
  x = [:caesar, :md5, :sha1, :bsd_position, :scrabble_hash, :length ].map do |hsh_type|
    "%-25s" % StupidHashes.minhash(words, hsh_type).first.to_s
  end
  puts [x, words.join(" ")].join("\t")
end
