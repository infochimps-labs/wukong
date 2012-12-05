#!/usr/bin/env ruby
$LOAD_PATH.unshift File.expand_path('../../lib', File.dirname(__FILE__))
require          'wukong/script'
require_relative './logline'

# cat data/swk-100.tsv      | ./histograms.rb --map | sort > data/swk-hist-map.tsv
# cat data/swk-hist-map.tsv | ./histograms.rb --reduce     > data/swk-hist.tsv

class HistogramsMapper < Wukong::Streamer::ModelStreamer
  self.model_klass = Logline
  def process visit
    yield [visit.path, visit.day_hr]
  end
end

class HistogramsReducer < Wukong::Streamer::Reducer
  def get_key path, day_hr
    [path, day_hr]
  end
  def start!(*args)
    @count = 0
    super
  end
  def accumulate path, day_hr
    @count += 1
  end
  def finalize
    yield [key, @count]
  end
end

# Wukong.run( HistogramsMapper )
Wukong.run( HistogramsMapper, HistogramsReducer, :sort_fields => 3 )
