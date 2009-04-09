#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/../lib'
require 'wukong'
require 'wukong/streamer/count_keys'
require 'wukong/streamer/count_lines'

#
#
module CountKeys
  # Identity Mapper
  class Reducer < Wukong::Streamer::CountLines
    require 'active_support'
    require 'action_view/helpers/number_helper'; include ActionView::Helpers::NumberHelper

    # Override to look nice
    def formatted_count item, key_count
      key_count_str = number_with_delimiter(key_count.to_i, :delimiter => ',')
      "%-25s\t%12s" % [item, key_count_str]
    end
  end

  #
  class Script < Wukong::Script
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
end

#
# Executes the script only if run from command line
#
if __FILE__ == $0
  CountKeys::Script.new(nil, CountKeys::Reducer).run
end
