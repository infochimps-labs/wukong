#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/..'
require 'wukong'

#
# Probabilistically emit some fraction of record/lines
#
# Set the sampling fraction at the command line using the
#   --sampling_fraction=
# option: for example, to take a random 1/1000th of the lines in huge_files,
#  ./examples/sample_records.rb --sampling_fraction=0.001 --go huge_files sampled_files
#
class Mapper < Wukong::Streamer::LineStreamer
  include Wukong::Streamer::Filter

  #
  # floating-point number between 0 and 1 giving the fraction of lines to emit:
  # at sampling_fraction=1 all records are emitted, at 0 none are.
  #
  # Takes its value from a mandatory command-line option
  #
  def sampling_fraction
    @sampling_fraction ||= ( options[:sampling_fraction] && options[:sampling_fraction].to_f ) or
      raise "Please supply a --sampling_fraction= argument, a decimal number between 0 and 1"
  end

  #
  # randomly decide to emit +sampling_fraction+ fraction of lines
  #
  def emit? line
    rand < self.sampling_fraction
  end
end

class Script < Wukong::Script
  def default_options
    super.merge :reduce_tasks => 0
  end
end

#
# Executes the script
#
Script.new( Mapper, nil ).run
