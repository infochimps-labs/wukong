#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/..'
require 'wukong'


#
#
module CountKeys

  class Reducer < Wukong::Streamer::CountLines
  end

  #
  class Script < Wukong::Script
    def map_command
      %Q{ cut -d"\t" -f1 }
    end

    #
    # There's just the one key
    #
    def sort_fields()    1 end
    def partition_keys() 1 end
  end
end

#
# Executes the script only if run from command line
#
if __FILE__ == $0 
  CountKeys::Script.new(nil, CountKeys::Reducer).run 
end 
