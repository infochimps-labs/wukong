#!/usr/bin/env ruby
require 'extlib/class'
require 'wukong'                       ; include Wukong
require 'wuclan/twitter'               ; include Wuclan::Twitter::Model
require 'wuclan/twitter/model/token'
require 'wukong/encoding'

File.open('smiley_test.tsv').each do |line| ; line.chomp!
  next if line.blank?
  smiley_text, explanation = line.split("\t",2)
  smiley_text.strip!
  tweet = Tweet.from_hash('text' => line)
  smiley = nil
  tweet.smileys{ |a_smiley| smiley = a_smiley }
  if ((! smiley) ||
      (smiley.text != smiley_text.wukong_encode)
      )
    puts [line, smiley.to_flat].flatten.compact.join("\t")
  end
end
