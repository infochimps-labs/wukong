#!/usr/bin/env ruby
$LOAD_PATH.unshift File.expand_path('../../lib', File.dirname(__FILE__))
require          'wukong/script'
require_relative './logline'

class HistogramsMapper < Wukong::Streamer::ModelStreamer
  self.model_klass = Logline
  def process visit
    yield [visit.path, visit.day_hr]
  end
end

# Wukong.run( HistogramsMapper )
Wukong.run( HistogramsMapper )
