#!/usr/bin/env ruby
$: << File.dirname(__FILE__)+'/..'
require 'wukong'

#
#
module CountKeys
  # 
  class Mapper < Wukong::Streamer::Base
    attr_accessor :keys_count
    def initialize *args
      self.keys_count = {}
    end
    def process key, *args
      key.gsub!(/-.*/, '')  # kill off the slug
      self.keys_count[key] ||= 0
      self.keys_count[key]  += 1
    end
    def stream *args
      super *args
      self.keys_count.each do |key, count|
        emit [key, count].to_flat
      end
    end
  end
  # Identity Mapper
  class Reducer < Wukong::Streamer::AccumulatingReducer
    attr_accessor :key_count
    require 'active_support'
    require 'action_view/helpers/number_helper'; include ActionView::Helpers::NumberHelper

    # Override to look nice
    def formatted_count item, key_count
      key_count_str = number_with_delimiter(key_count.to_i, :delimiter => ',')
      "%-25s\t%12s" % [item, key_count_str]
    end
    def reset!
      self.key_count = 0
    end
    def accumulate key, count
      self.key_count += count.to_i
    end
    def finalize
      yield formatted_count(key, key_count)
    end
  end

  #
  class Script < Wukong::Script
    # There's just the one field
    def default_options
      super.merge :sort_fields => 1, :reduce_tasks => 1
    end
  end
end

CountKeys::Script.new(CountKeys::Mapper, CountKeys::Reducer).run
