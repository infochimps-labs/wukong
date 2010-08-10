#!/usr/bin/env ruby
require 'rubygems'
require 'wukong'

class FooStreamer < Wukong::Streamer::LineStreamer
  def initialize *args
    super *args
    @line_no = 0
  end

  def process *args
    yield [@line_no, *args]
    @line_no += 1
  end
end

Wukong::Script.new(FooStreamer, FooStreamer).run
