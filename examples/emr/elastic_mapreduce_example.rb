#!/usr/bin/env ruby
Dir[File.dirname(__FILE__)+'/vendor/**/lib'].each{|dir| $: << dir }
require 'rubygems'
require 'wukong'

class FooStreamer < Wukong::Streamer::LineStreamer
  def initialize *args
    super *args
    @line_no = 0
  end

  def process *args
    yield ["%5d" % @line_no, *args]
    @line_no += 1
  end
end

Wukong::Script.new(FooStreamer, FooStreamer).run
