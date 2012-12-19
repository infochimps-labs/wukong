#!/usr/bin/env ruby
$LOAD_PATH.push(File.expand_path('../../../lib', File.dirname(__FILE__)))

require 'wukong'
require 'multi_json'
require 'gorillib'
require 'wu/wikipedia/models'

module Dbpedia
  class GetGeolocations < Wukong::Streamer::RecordStreamer

    def recordize(line)
      page_id, namespace, wikipedia_id, json_hsh, *stuff = super
      raise ArgumentError, "Too many fields: #{stuff}" if stuff.present?
      hsh = MultiJson.decode(json_hsh)
      [Wu::Wikipedia::DbpediaArticle.new(hsh)]
    end

    #
    def process(article)
      return if article.page_id.to_i == 0
      yield [
        article.page_id, article.namespace, article.wikipedia_id,
        article.longitude, article.latitude, article.quadkey]
    end
  end

end

Wukong::Script.new(Dbpedia::GetGeolocations).run
