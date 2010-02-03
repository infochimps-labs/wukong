#!/usr/bin/env ruby
# run like so:
# $> ruby average_value_frequecy.rb --run=local data/stats.tsv data/avf_out.tsv
require 'rubygems'
require 'wukong'

#
# Calculate the average value frequency (AVF) for each data row. AVF for a data
# point with m attributes is defined as:
#
#     avf = (1/m)* sum (frequencies of attributes 1..m)
#
# so with the data
#
#      1       15      30      25
#      2       10      10      20
#      3       50      30      30
#
# for the first row, avf = (1/3)*(1+2+1) ~= 1.33. An outlier is identified by
# a low AVF.
#
module AverageValueFrequency
  # Names for each column's attribute, in order
  ATTR_NAMES = %w[length width height]

  class HistogramMapper < Wukong::Streamer::RecordStreamer
    # unroll each row from
    #     [id,   val1,   val2, ....]
    # into
    #     [attr1,   val1]
    #     [attr2,   val2]
    #     ...
    def process id, *values
      ATTR_NAMES.zip(values).each do |attr, val|
        yield [attr, val]
      end
    end
  end

  #
  # Build a histogram of values
  #
  class HistogramReducer < Wukong::Streamer::CountingReducer
    # use the attr and val as the key
    def get_key attr, val=nil, *_
      [attr, val]
    end
  end

  class AvfRecordMapper < Wukong::Streamer::RecordStreamer
    # average the frequency of each value
    def process id, *values
      sum = 0.0
      ATTR_NAMES.zip(values).each do |attr, val|
        sum += histogram[ [attr, val] ].to_i
      end
      avf = sum / ATTR_NAMES.length.to_f
      yield [id, avf, *values]
    end

    # Load the histogram from a tab-separated file with
    #   attr    val   freq
    def histogram
      return @histogram if @histogram
      @histogram = { }
      File.open(options[:histogram_file]).each do |line|
        attr, val, freq = line.chomp.split("\t")
        @histogram[ [attr, val] ] = freq
      end
      @histogram
    end
  end
end

Settings.use :commandline ; Settings.resolve!
if Settings[:histogram]
  Wukong::Script.new(AverageValueFrequency::HistogramMapper, AverageValueFrequency::HistogramReducer).run
elsif Settings[:avf]
  Wukong::Script.new(AverageValueFrequency::AvfRecordMapper, nil).run
else
  raise "Please specify either --histogram (for first round) or --avf (second round)"
end
