#!/usr/bin/env ruby
require 'rubygems'
require 'wukong/script'

Settings.define :sampling_fraction, :type => Float, :required => true, :description => "floating-point number between 0 and 1 giving the fraction of lines to emit: at sampling_fraction=1 all records are emitted, at 0 none are."

#
# Probabilistically emit some fraction of record/lines
#
# Set the sampling fraction at the command line using the
#   --sampling_fraction=
# option: for example, to take a random 1/1000th of the lines in huge_files,
#  ./examples/sample_records.rb --sampling_fraction=0.001 --run huge_files sampled_files
#
class Mapper < Wukong::Streamer::LineStreamer
  include Wukong::Streamer::Filter

  #
  # randomly decide to emit +sampling_fraction+ fraction of lines
  #
  def emit? line
    rand < Settings.sampling_fraction
  end
end

#
# Executes the script
#
Wukong.run( Mapper,
  nil,
  :reduce_tasks => 0,
  :reuse_jvms   => true
  )
