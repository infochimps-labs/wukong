#!/usr/bin/env ruby
require 'rubygems'
require 'wukong/script'

#
# Use the stanford NLP parse to split a piece of text into sentences
#
# @example
#   SentenceParser.split("Beware the Jabberwock, my son! The jaws that bite, the claws that catch! Beware the Jubjub bird, and shun The frumious Bandersnatch!")
#   # => [["Beware", "the", "Jabberwock", ",", "my", "son", "!"], ["The", "jaws", "that", "bite", ",", "the", "claws", "that", "catch", "!"], ["Beware", "the", "Jubjub", "bird", ",", "and", "shun", "The", "frumious", "Bandersnatch", "!"]]
#
class SentenceParser
  def self.processor
    return @processor if @processor
    require 'rubygems'
    require 'stanfordparser'
    @processor = StanfordParser::DocumentPreprocessor.new
  end

  def self.split line
    processor.getSentencesFromString(line).map{|s| s.map{|w| w.to_s } }
  end
end

#
# takes one document per line
# splits into sentences
#
class WordNGrams < Wukong::Streamer::LineStreamer
  def recordize line
    line.strip!
    line.gsub!(%r{^<http://dbpedia.org/resource/([^>]+)> <[^>]+> \"}, '') ; title = $1
    line.gsub!(%r{\"@en \.},'')
    [title, SentenceParser.split(line)]
  end

  def process title, sentences
    sentences.each_with_index do |words, idx|
      yield [title, idx, words].flatten
    end
  end
end

Wukong.run WordNGrams, nil, :partition_fields => 1, :sort_fields => 2

# ---------------------------------------------------------------------------
#
# Run Time:
#
#   Job Name: dbpedia_abstract_to_sentences.rb---/data/rawd/encyc/dbpedia/dbpedia_dumps/short_abstracts_en.nt---/data/rawd/encyc/dbpedia/dbpedia_parsed/short_abstract_sentences
#   Status: Succeeded
#   Started at: Fri Jan 28 03:14:45 UTC 2011
#   Finished in: 41mins, 50sec
#   3 machines: master m1.xlarge, 2 c1.xlarge workers; was having some over-memory issues on the c1.xls
#
#                                     Counter      Reduce       Total
#   SLOTS_MILLIS_MAPS                       0              10 126 566
#   Launched map tasks                      0                      15
#   Data-local map tasks                    0                      15
#   SLOTS_MILLIS_REDUCES                    0                   1 217
#   HDFS_BYTES_READ             1 327 116 133           1 327 116 133
#   HDFS_BYTES_WRITTEN          1 229 841 020           1 229 841 020
#   Map input records               3 261 096               3 261 096
#   Spilled Records                         0                       0
#   Map input bytes             1 326 524 800           1 326 524 800
#   SPLIT_RAW_BYTES                     1 500                   1 500
#   Map output records              9 026 343               9 026 343
#
#   Job Name: dbpedia_abstract_to_sentences.rb---/data/rawd/encyc/dbpedia/dbpedia_dumps/long_abstracts_en.nt---/data/rawd/encyc/dbpedia/dbpedia_parsed/long_abstract_sentences
#   Status: Succeeded
#   Started at: Fri Jan 28 03:23:08 UTC 2011
#   Finished in: 41mins, 11sec
#   3 machines: master m1.xlarge, 2 c1.xlarge workers; was having some over-memory issues on the c1.xls
#
#                                     Counter      Reduce       Total
#   SLOTS_MILLIS_MAPS                       0              19 872 357
#   Launched map tasks                      0                      29
#   Data-local map tasks                    0                      29
#   SLOTS_MILLIS_REDUCES                    0                   5 504
#   HDFS_BYTES_READ             2 175 900 769           2 175 900 769
#   HDFS_BYTES_WRITTEN          2 280 332 736           2 280 332 736
#   Map input records               3 261 096               3 261 096
#   Spilled Records                         0                       0
#   Map input bytes             2 174 849 644           2 174 849 644
#   SPLIT_RAW_BYTES                     2 533                    2533
#   Map output records             15 425 467              15 425 467
