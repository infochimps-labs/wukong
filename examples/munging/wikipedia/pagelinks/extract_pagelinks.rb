#!/usr/bin/env ruby

require 'wukong'
require 'wukong/streamer/sql_streamer'
require 'wukong/streamer/encoding_cleaner'

module PagelinksExtractor
  class Mapper < Wukong::Streamer::SQLStreamer
    include Wukong::Streamer::EncodingCleaner
    columns [:int, :int, :string]
  end
end

Wukong::Script.new(PagelinksExtractor::Mapper, nil).run
