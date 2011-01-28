#!/usr/bin/env ruby
require 'rubygems'
require 'backports'
require 'backports/1.8.8'
require 'extlib'

class Source
  # include Enumerable
  attr_reader :streamer

  def recordize line
    # line.strip.split("\t")
    [line[0..5]]
  end

  def each *args
    $stdin.each(*args) do |raw_record|
      record = recordize(raw_record)
      next if record.blank?
      yield *record
      break if raw_record =~ /end/
    end
  end
end

# def process_group group
# end
#

class Streamer

  def recordize line
    [line[0..5]]
  end

  def each_group
    while not $stdin.eof? do
      Enumerator.new do |yielder|
        $stdin.each do |line|
        yield yielder
          p yielder
          break if line =~ /end/
        end
      end
    end
  end
end

foo = Streamer.new

foo.each_group do |group|
  puts "hi"
  p group.each do |line|
    p line.reverse
  end
  #   .map do |record|
  #   1
  # end
end


# i = 0
# # s = source.new(Streamer.new)
# $stdin.each do
#   process_group do |output|
#     puts output
#   end
#   $stderr.puts [Time.now, i] if (i += 1) % 10 == 0
# end


