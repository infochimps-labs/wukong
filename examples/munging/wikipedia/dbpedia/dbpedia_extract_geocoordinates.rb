#!/usr/bin/env ruby
require_relative './dbpedia_common'

# ## Usage
#
# Flattens the wikipedia 'enwiki-latest-pages-articles.xml.gz' into a
# one-line-per-record heap.
#
#    examples/munging/wikipedia/dbpedia/extract_geolocations.rb --rm --run \
#      /data/origin/wikipedia/dbpedia/geo_coordinates_en.nq \
#      /data/results/wikipedia/dbpedia-geo_coordinates_en.tsv
#

# ## Sample Pig Schema
#
# geolocations = LOAD '$geolocations' AS
#   (id:long, namespace:int, title:chararray, longitude:float, latitude:float);
#

module Dbpedia
  class GeocoordinatesExtractor < Wukong::Streamer::LineStreamer
    include MungingUtils

    KNOWN_LINE_RE = %r{\A(?:
         \#\sstarted
      |  <http://dbpedia\.org/resource/[^>]+>\s
         <http://(
            www\.georss\.org/georss/point
         |  www\.w3\.org/1999/02/22-rdf-syntax-ns\#type
         |  www\.w3\.org/2003/01/geo/wgs84_pos\#(?:lat|long)
      )>
    )}x

    # it's on one line in the actual dataset; split here for readability
    GEO_RSS_RE = %r{\A
         <http://dbpedia\.org/resource/(?<title>[^>]+)>
      \s <http://www\.georss\.org/georss/point>
      \s "(?<lat>#{DECIMAL_NUM_RE})\s(?<lng>#{DECIMAL_NUM_RE})"@en
      \s <http://en\.wikipedia\.org/wiki/(?:[^\?]+)\?oldid=(?<article_id>\d+)>
      \s \.
    \z}x

    def warn_record(desc, record=nil)
      record_info = MultiJson.encode(record)[0..1000] rescue "(unencodeable record) #{record.inspect[0..100]}"
      Log.warn [desc, record_info].join("\t")
    end

    ARTICLE_NAMESPACE = 0

    # The file is in that godawful semantic web format. Let's fix that.
    #
    #     <http://dbpedia.org/resource/Alabama> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.opengis.net/gml/_Feature> <http://en.wikipedia.org/wiki/Alabama?oldid=495507959> .
    #     <http://dbpedia.org/resource/Alabama> <http://www.w3.org/2003/01/geo/wgs84_pos#lat> "33.0"^^<http://www.w3.org/2001/XMLSchema#float> <http://en.wikipedia.org/wiki/Alabama?oldid=495507959> .
    #     <http://dbpedia.org/resource/Alabama> <http://www.w3.org/2003/01/geo/wgs84_pos#long> "-86.66666666666667"^^<http://www.w3.org/2001/XMLSchema#float> <http://en.wikipedia.org/wiki/Alabama?oldid=495507959> .
    #     <http://dbpedia.org/resource/Alabama> <http://www.georss.org/georss/point> "33.0 -86.66666666666667"@en <http://en.wikipedia.org/wiki/Alabama?oldid=495507959> .
    #
    # The lines seem to be redundant, with the georss one containing what we need, so just filter for those
    #
    def process(line)
      if not KNOWN_LINE_RE.match(line) then warn_record("Unrecognized line type", line) ; return ; end
      return unless $1 == 'www.georss.org/georss/point'
      geo_info = GEO_RSS_RE.match(line)
      if not geo_info then warn_record("Unrecognized georss line", line) ; return ; end

      result = [
        geo_info[:article_id],
        ARTICLE_NAMESPACE, # the dbpedia stuff is all NS 0
        geo_info[:title],
        geo_info[:lng],
        geo_info[:lat],
      ]
      yield result
    end
  end

end

Wukong::Script.new(Dbpedia::GeocoordinatesExtractor, nil).run
