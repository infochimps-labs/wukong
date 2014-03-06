#!/usr/bin/env ruby
require_relative './common'

class BreadcrumbsMapper < Wukong::Streamer::ModelStreamer
  self.model_klass = Logline
  def process visit, *args
    # return unless Settings.page_types.include?(visit.page_type)
    yield [visit.ip, visit.requested_at.to_i, visit.path]
  end
end

class BreadcrumbEdgesReducer < Wukong::Streamer::Reducer
  def get_key(ip, itime, path)
    [ip]
  end
  def start!(*args)
    @paths = Set.new
    super
  end
  def accumulate ip, itime, path
    @paths << path
  end

  # for each pair of paths, emit the edge in both directions
  def finalize
    @paths = @paths.to_a
    while @paths.present?
      from = @paths.shift
      @paths.each do |into|
        yield [key, from, into]
        yield [key, into, from]
      end
    end
  end
end


Wukong.run( BreadcrumbsMapper, BreadcrumbEdgesReducer, :sort_fields => 2 )
