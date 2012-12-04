#!/usr/bin/env ruby
require_relative './common'

class HistogramsMapper < Wukong::Streamer::ModelStreamer
  self.model_klass = Logline
  def process visit
    yield [visit.path, visit.day_hr]
  end
end

# Wukong.run( HistogramsMapper )
Wukong.run( HistogramsMapper )
