#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'rubygems'
require 'faster_csv'
require 'imw' ; include IMW
require 'hadoop_utils'; include HadoopUtils
# as_dset __FILE__


#
# This should:
# * for mutable objects
# * discard the timestamp and record-time-id, and compare everything else
#   (incl. the object class which it currently doesn't)
#

#
#
#
class LineTimestampUniqifier
  attr_accessor :last_line
  def initialize
    self.last_line = nil
  end
  def is_repeated? line
    # Do surgery removing the timestamp
    resource, item_key, scraped_at, val = line.chomp.split("\t",4)
    this_line = [resource, item_key, val].join("\t")
    # Since the only things that will be de-uniqued have all-identical
    # prefixes (differ only in their timestamp), and the lines are lexically
    # sorted (?) this should be the earliest
    if this_line == self.last_line
      true
    else
      self.last_line = this_line
      false
    end
  end
end


# ===========================================================================
#
# parse each line in STDIN
#
line_timestamp_uniqifier = LineTimestampUniqifier.new
$stdin.each do |line|
  line.chomp!
  next if line.blank? || line_timestamp_uniqifier.is_repeated?(line)
  line.gsub!(/\A([\w]+)(?:-[^\t]*)?\t/, "\\1\t") # strip the keyspace-broadening slug
  puts line
end


# line.gsub(/\A([\w\-]+)\t[^\t]+\t(.*)\t\d{8}-?\d{6}\s*$/,"\\1\t\\2") # KLUDGE -- I don't know why the \s* on the end is necessary... but it is, so leave it.
