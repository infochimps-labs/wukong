#!/usr/bin/env ruby
$stderr.puts `jar xvf *.jar `
$stderr.puts `tar xvjf *.tar.bz2 `
$stderr.puts `ls -lR . /mnt/var/lib/hadoop/mapred/taskTracker/archive `

Dir['/mnt/var/lib/hadoop/mapred/taskTracker/archive/**/lib'].each{|dir| $: << dir }
Dir['./**/lib'].each{|dir| $: << dir }
require 'rubygems'
require 'wukong'
begin
  require 'wukong/script/emr_command'
rescue
  nil
end

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

case
when ($0 =~ /mapper\.rb/) then Settings[:map] = true
when ($0 =~ /reducer\.rb/) then Settings[:reduce] = true
end

Wukong::Script.new(FooStreamer, FooStreamer).run
puts 'done!'
puts $0
