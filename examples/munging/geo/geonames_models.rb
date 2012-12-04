# -*- coding: utf-8 -*-
# {"type":"Feature",
#  "id":"3cc54602f2d69c1111dc35f0aaa92240",
#  "geometry":{"type":"Point","coordinates":[42.5,11.5]},
#  "properties":{
#    "geonameid":"223816","country_code":"DJ","admin1_code":"00",
#    "feature_code":"PCLI","feature_class":"A",
#    "asciiname":"Republic of Djibouti","name":"Republic of Djibouti","alternatenames":"Cîbûtî,...",
#    "modification_date":"2011-07-09",
#    "timezone":"Africa/Djibouti","gtopo30":"668","population":"740528"}}


# {"type":"Feature","id":"5b66ac7270763facfe1e9ab9c1bf99f8",
# "geometry":{"type":"Point","coordinates":[-98.5,39.76]},
# "properties":{
# "modification_date":"2011-04-27","_type":"geo/geonames_country",
# "asciiname":"United States","name":"United States","gtopo30":"537","geonameid":"6252001",
# "feature_code":"PCLI","country_code":"US","feature_class":"A",
# "alternatenames":"...","admin1_code":"00","population":"310232863"}}

module Geo

  class GeonamesPlace
    include Gorillib::Model
    class_attribute :place_klass ; self.place_klass = ::Geo::Place

    field :name,              String
    field :asciiname,         String
    field :geonameid,         String
    field :country_code,      String
    field :admin1_code,       String, blankish: [0, "0", "00", nil, ""]
    field :feature_code,      String
    field :feature_class,     String
    #
    field :modification_date, String
    field :timezone,          String
    #
    field :gtopo30,           Float,   blankish: ["-9999", -9999, nil, ""], doc: "Elevation in the [GTOPO30](http://en.wikipedia.org/wiki/GTOPO30) model"
    field :longitude,         Float
    field :latitude,          Float
    #
    field :population,        Integer, blankish: [0, "0", nil, ""]
    field :alternatenames,    String

    # because 'Saint Helena, Ascension and Tristan da Cunha' is an official
    # country name (and others like it
    def alternate_names_with_pipes
      # comma ',' with no spaces separates names; comma space ', ' is internal.
      an = alternatenames.gsub(/,/, '|').gsub(/\| /, ', ')
      ([name, asciiname] + an.split('|')).uniq.join("|")
    end

    def to_place
      attrs = {
        name:            asciiname,
        official_name:   name,
        geonames_id:     "gn:#{geonameid}",
        country_id:      country_code.downcase,
        admin1_id:       admin1_code,
        feature_cat:     feature_class,
        feature_subcat:  feature_code,
        alternate_names: alternate_names_with_pipes,
        updated_at:      modification_date,
        timezone:        timezone,
        elevation:       gtopo30,
        longitude:       longitude,
        latitude:        latitude,
        population:      population,
      }
      place_klass.receive(attrs)
    end
  end

  # Stub class: Geonames JSON elements have :_type = geo/geonames_country
  class GeonamesCountry < GeonamesPlace
    self.place_klass = Geo::Country
  end

  # http://download.geonames.org/export/zip/
  #
  # country code      : iso country code, 2 characters
  # postal code       : varchar(20)
  # place name        : varchar(180)
  # admin name1       : 1. order subdivision (state) varchar(100)
  # admin code1       : 1. order subdivision (state) varchar(20)
  # admin name2       : 2. order subdivision (county/province) varchar(100)
  # admin code2       : 2. order subdivision (county/province) varchar(20)
  # admin name3       : 3. order subdivision (community) varchar(100)
  # admin code3       : 3. order subdivision (community) varchar(20)
  # latitude          : estimated latitude (wgs84)
  # longitude         : estimated longitude (wgs84)
  # accuracy          : accuracy of lat/lng from 1=estimated to 6=centroid
  class GeonamesPostal
    field :country_id,   String, doc: "iso country code, 2 characters"
    field :postal_id,    String, doc: "varchar(20)"
    field :name,         String, doc: "varchar(180)"
    field :admin1_name,  String, doc: "1. order subdivision (state) varchar(100)"
    field :admin1_id,    String, doc: "1. order subdivision (state) varchar(20)"
    field :admin2_name,  String, doc: "2. order subdivision (county/province) varchar(100)"
    field :admin2_id,    String, doc: "2. order subdivision (county/province) varchar(20)"
    field :admin3_name,  String, doc: "3. order subdivision (community) varchar(100)"
    field :admin3_id,    String, doc: "3. order subdivision (community) varchar(20)"
    field :latitude,     String, doc: "estimated latitude (wgs84)"
    field :longitude,    String, doc: "estimated longitude (wgs84)"
    field :accuracy,     String, doc: "accuracy of lat/lng from 1=estimated to 6=centroid"
  end
end
