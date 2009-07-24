#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/../lib'
require 'wukong'
require 'wukong/streamer/count_keys'
require 'wukong/streamer/count_lines'

#
#
class CountKeysReducer < Wukong::Streamer::CountLines
  #
  # Taken from the actionpack Rails component ('action_view/helpers/number_helper')
  #
  # Formats a +number+ with grouped thousands using +delimiter+. You
  # can customize the format using optional <em>delimiter</em> and <em>separator</em> parameters.
  # * <tt>delimiter</tt>  - Sets the thousands delimiter, defaults to ","
  # * <tt>separator</tt>  - Sets the separator between the units, defaults to "."
  #
  #  number_with_delimiter(12345678)      => 12,345,678
  #  number_with_delimiter(12345678.05)   => 12,345,678.05
  #  number_with_delimiter(12345678, ".")   => 12.345.678
  def number_with_delimiter(number, delimiter=",", separator=".")
    begin
      parts = number.to_s.split('.')
      parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
      parts.join separator
    rescue
      number
    end
  end

  # Override to look nice
  def formatted_count item, key_count
    key_count_str = number_with_delimiter(key_count.to_i)
    "%-25s\t%12s" % [item, key_count_str]
  end
end

#
class CountKeysScript < Wukong::Script
  def map_command
    # Use `cut` to extract the first field
    %Q{ cut -d"\t" -f1 }
  end

  #
  # There's just the one field
  #
  def default_options
    super.merge :sort_fields => 1
  end
end

# Executes the script when run from command line
if __FILE__ == $0
  CountKeysScript.new(nil, CountKeysReducer).run
end
