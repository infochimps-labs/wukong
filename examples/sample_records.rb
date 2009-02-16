#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/..'
require 'wukong'

#
# Probabilistically emit some fraction of record/lines
#
# Set the sampling fraction at the command line using the
#   --sampling_fraction=
# option.
#
#

module SampleRecords
  class Mapper < Wukong::Streamer::Filter
    attr_accessor :sampling_fraction
    def initialize options, *args
      super options, *args
      self.sampling_fraction = options[:sampling_fraction].to_f or
        raise "Please supply a --sampling_fraction= argument, a decimal number between 0 and 1"
    end

    def emit? line
      rand < self.sampling_fraction
    end
  end

  #
  #
  class Script < Wukong::Script
  end
end

#
# Executes the script
#
SampleRecords::Script.new(
  SampleRecords::Mapper,
  nil
  ).run
