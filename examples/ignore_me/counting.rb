#!/usr/bin/env ruby
require 'rubygems'
require 'wukong/script'

require 'bloomfilter-rb'

SIZE = 2**24

class BucketCounter
  def initialize(opts = {})
    @opts = {
      :size    => 100,
      :server => {}
    }.merge opts
    @db   = ::Redis.new(@opts[:server])
    @size = opts[:size]
  end

  def key_for val
    (val.hash % @size)
  end

  def insert(val)
    @db.incr(key_for(val))
  end
  alias :<< :insert

  def delete(val)
    if @db.decr(key_for(val)).to_i <= 0
      @db.del(key_for(val))
    end
  end

  def [](val)
    @db.get(key_for(val)).to_i
  end

  def clear
    @db.flushdb
  end
end

bf     = BucketCounter.new(:size => 1_000, :server => {:host => 'localhost'})
bf.clear
counts = Hash.new{|h,k| h[k] = 0 }

doc = File.read(__FILE__)
doc.split(/\W+/).each do |word|
  counts[word] += 1
  bf << word
end

counts.keys.sort.each do |word|
  puts [ bf[word] - counts[word], bf[word], counts[word], word.hash % SIZE, word ].join("\t")
end
