#!/usr/bin/env ruby
Dir[File.dirname(__FILE__)+'/vendor/**/lib'].each{|dir| $: << dir }
require 'rubygems'
require 'wukong/script'
require 'wukong/script/emr_command'

#
# * Copy the emr.yaml from here into ~/.wukong/emr.yaml
#   and edit it to suit.
# * Download the Amazon elastic-mapreduce runner. Get a copy from
#   http://elasticmapreduce.s3.amazonaws.com/elastic-mapreduce-ruby.zip
# * Find out what breaks, fix it or ask us for help (coders@infochimps.org) and
#   submit a patch
#

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
