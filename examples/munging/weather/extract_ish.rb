#!/usr/bin/env ruby
# encoding: UTF-8

require 'wukong'
require 'wukong/streamer/flatpack_streamer'

module Weather
  class Mapper < Wukong::Streamer::FlatPackStreamer
    format "_4  i6    i5   s8      s4  sD6e3  D7e3   s5   i5   s5   s4  i3 ssD4e1ii5   ssbi6    sssD5e1 sD5e1 sD5e1 ss*"
  end
end

Wukong::Script.new(Weather::Mapper, nil).run
