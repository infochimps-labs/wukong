#!/usr/bin/env ruby
$: << File.dirname(__FILE__)
require 'rubygems'
require 'wukong/script'

Settings.define :ripd_root, :default => '/data/chimpmark/ripd'
BNC_SOURCE_FILE='ucrel.lancs.ac.uk/bncfreq/lists/1_1_all_fullalpha.txt'

# File 1_1_all_fullalpha.txt -- 794771 lines
#
# cat /data/chimpmark/ripd/ucrel.lancs.ac.uk/bncfreq/lists/1_1_all_fullalpha.txt | ./bnc_word_freq.rb --map | sort -nk3 > /data/chimpmark/rawd/bnc_word_freq/bnc_word_freq.tsv

class BncParser < Wukong::Streamer::RecordStreamer
  def before_stream
    @head_word, @part_of_speech, @head_word_stats = ["","",[]]
    $stdin.readline
    $stdin.readline
  end

  def process _, word, pos, variant, freq_ppm, range, dispersion
    word_stats = [freq_ppm, range, dispersion]

    unless word == "@"                # lemma for a different head word
      @head_word       = word
      @part_of_speech  = pos
      @head_word_stats = word_stats
    end

    weirdness = (@head_word =~ /[^a-zA-Z]/)

    if    variant == '%'  # head word with lemmas
      word_stats = ['','','']
    elsif variant == ':'  # head word with no lemmas
      variant = word
    else
      weirdness = weirdness || (variant =~ /[^a-zA-Z]/)
    end
    yield [@head_word, @part_of_speech, @head_word_stats, variant, word_stats, (weirdness ? 1 : 0)].flatten.join("\t")
  end
end

Wukong.run(
  BncParser, nil
  )
