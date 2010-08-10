#!/usr/bin/env ruby

Dir[File.dirname(__FILE__)+'/**/lib'].each{|dir| $: << dir }
require 'rubygems'
require 'wukong'
require 'wukong/script/emr_command'

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
puts 'done!'
puts $0
