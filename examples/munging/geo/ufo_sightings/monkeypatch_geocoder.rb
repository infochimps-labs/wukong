# -*- coding: utf-8 -*-
Settings.define :yahoo_consumer_key, description: "Yahoo API Consumer Key"
Settings.define :yahoo_secret_key,   description: "Yahoo API Secret Key"
Settings.define :bing_key,           description: "Bing Mapping Secret Key"

class RawGeocoderPlace
  field :woeid,         String
  field :woetype,       String
end

module Geocoder
  def self.select_provider(provider)
    Geocoder.configure(api_providers[provider].merge(lookup: provider))
  end

  def self.api_providers
    @api_providers ||= {
      # yahoo:     { api_key: [Settings.yahoo_consumer_key, Settings.yahoo_secret_key], },
      # bing:      { api_key: Settings.bing_key, },
      nominatim: { api_key: Settings.email },
    }
  end

  def self.batch
    api_providers.keys.each do |provider|
      Geocoder.select_provider(provider)
      yield(provider)
    end
  end

  module Lookup
    class Base

      def search(query, options = {})
        query = Geocoder::Query.new(query, options) unless query.is_a?(Geocoder::Query)
        results(query).map{ |r|
          result = result_class.new(r)
          result.cache_hit = @cache_hit if cache
          result
        }.tap{|arr| ch = @cache_hit ; arr.define_singleton_method(:cache_hit){ ch } }
      end
    end

    class Nominatim < Base
      def query_url_params(query)
        params = {
          :format => "json",
          # :polygon_geojson => "1",
          :addressdetails => "1",
          :"accept-language" => configuration.language,
          :email => configuration.api_key,
        }.merge(super)
        if query.reverse_geocode?
          lat,lon = query.coordinates
          params[:lat] = lat
          params[:lon] = lon
        else
          params[:q] = query.sanitized_text
        end
        params
      end
    end

  end

  module Result
    class Yahoo < Base
      def bbox
        return unless boundingbox
        [boundingbox['west'], boundingbox['south'], boundingbox['east'], boundingbox['north']]
      end
      def confidence
        quality
      end
    end

    class Bing < Base
      def bbox
        bb = @data['bbox']
        [bb[1], bb[0], bb[3], bb[2]]
      end
      def place_type
        @data['entityType']
      end
    end

    class Nominatim < Base
      def name
        display_name
      end
      def bbox
        return unless boundingbox
        [boundingbox[2], boundingbox[0], boundingbox[3], boundingbox[1]].map(&:to_f)
      end
    end
  end


end


# ["Aalborg (Denmark),", [
#     {
#       "place_id"       => "251033",
#       "licence"        => "Data © OpenStreetMap contributors, ODbL 1.0. http://www.openstreetmap.org/copyright",
#       "osm_type"       => "node",
#       "osm_id"         => "60120144",
#       "boundingbox"    => ["57.0482063293457", "57.048210144043", "9.91966247558594", "9.91966342926025"],
#       "lat"            => "57.0482095",
#       "lon"            => "9.9196625",
#       "display_name"   => "Aalborg, Aalborg Kommune, Region Nordjylland, Denmark",
#       "class"          => "place",
#       "type"           => "city",
#       "importance"     => 0.74089576136566,
#       "icon"           => "http://nominatim.openstreetmap.org/images/mapicons/poi_place_city.p.20.png",
#       "address"        => {
#         "city"         => "Aalborg",
#         "county"       => "Aalborg Kommune",
#         "state"        => "Region Nordjylland",
#         "country"      => "Denmark",
#         "country_code" => "dk"
#       }
#     }, {
#       "place_id"       => "277590",
#       "licence"        => "Data © OpenStreetMap contributors, ODbL 1.0. http://www.openstreetmap.org/copyright",
#       "osm_type"       => "node",
#       "osm_id"         => "57355234",
#       "boundingbox"    => ["57.0432090759277", "57.043212890625", "9.91656017303467", "9.91656112670898"],
#       "lat"            => "57.0432091",
#       "lon"            => "9.916561",
#       "display_name"   => "Aalborg, John F. Kennedys Plads, Nørresundby, Aalborg, Aalborg Kommune, Region Nordjylland, 9000, Denmark",
#       "class"          => "railway",
#       "type"           => "station",
#       "importance"     => 0.201,
#       "icon"           => "http://nominatim.openstreetmap.org/images/mapicons/transport_train_station2.p.20.png",
#       "address"        => {
#         "station"      => "Aalborg",
#         "road"         => "John F. Kennedys Plads",
#         "suburb"       => "Nørresundby",
#         "city"         => "Aalborg",
#         "county"       => "Aalborg Kommune",
#         "state"        => "Region Nordjylland",
#         "postcode"     => "9000",
#         "country"      => "Denmark",
#         "country_code" => "dk"}
#     },{
#       "place_id"       => "11682166",
#       "licence"        => "Data © OpenStreetMap contributors, ODbL 1.0. http://www.openstreetmap.org/copyright",
#       "osm_type"       => "node",
#       "osm_id"         => "1040023949",
#       "boundingbox"    => ["57.0432395935059", "57.0432434082031", "9.91631889343262", "9.91631984710693"],
#       "lat"            => "57.0432411",
#       "lon"            => "9.916319",
#       "display_name"   => "Aalborg, Prinsensgade, Nørresundby, Aalborg, Aalborg Kommune, Region Nordjylland, 9000, Denmark",
#       "class"          => "railway",
#       "type"           => "station",
#       "importance"     => 0.201,
#       "icon"           => "http://nominatim.openstreetmap.org/images/mapicons/transport_train_station2.p.20.png",
#       "address"        => {
#         "station"      => "Aalborg",
#         "road"         => "Prinsensgade",
#         "suburb"       => "Nørresundby",
#         "city"         => "Aalborg",
#         "county"       => "Aalborg Kommune",
#         "state"        => "Region Nordjylland",
#         "postcode"     => "9000",
#         "country"      => "Denmark",
#         "country_code" => "dk"
#       }
#     }

# { quality:       "19",
#   latitude:      "47.274321",
#   longitude:     "-120.832726",
#   offsetlat:     "47.274319",
#   offsetlon:     "-120.832718",
#   radius:        "436100",
#   boundingbox:   {
#     north:       "49.00491",
#     south:       "45.543732",
#     east:        "-116.916054",
#     west:        "-124.749397"
#   },
#   name:          "",
#   line1:         "",
#   line2:         "Washington",
#   line3:         "",
#   line4:         "United States",
#   cross:         "",
#   house:         "",
#   street:        "",
#   xstreet:       "",
#   unittype:      "",
#   unit:          "",
#   postal:        "",
#   neighborhood:  "",
#   city:          "",
#   county:        "",
#   state:         "Washington",
#   country:       "United States",
#   countrycode:   "US",
#   statecode:     "WA",
#   countycode:    "",
#   timezone:      "America/Los_Angeles",
#   uzip:          "",
#   hash:          "",
#   woeid:         "2347606",
#   woetype:       "8"
# }


# ["Biesenthal (Germany),", [
#     #<Geocoder::Result::Bing:0x007fcc34838af8
#     @data={
#       __type:             "Location:http://schemas.microsoft.com/search/local/ws/rest/v1",
#       bbox:               [52.71528625488281, 13.51197624206543, 52.81573486328125, 13.780583381652832],
#       name:               "Biesenthal, BB, Germany",
#       point:              {
#         type:               "Point",
#         coordinates:        [52.76531982421875, 13.64486026763916]},
#       address:            {
#         adminDistrict:      "BB",
#         adminDistrict2:     "Barnim",
#         countryRegion:      "Germany",
#         formattedAddress:   "Biesenthal, BB, Germany",
#         locality:           "Biesenthal"},
#       confidence:         "Medium",
#       entityType:         "PopulatedPlace",
#       geocodePoints:      [{
#           type:               "Point",
#           coordinates:        [52.76531982421875, 13.64486026763916],
#           calculationMethod:  "Rooftop",
#           usageTypes:         ["Display"]}],
#       matchCodes:         ["Ambiguous", "Good"]}, @cache_hit=false>,
#     #<Geocoder::Result::Bing:0x007fcc34838990
#     @data={
#       __type:             "Location:http://schemas.microsoft.com/search/local/ws/rest/v1",
#       bbox:               [52.74232864379883, 11.558028221130371, 52.74964141845703, 11.566473007202148],
#       name:               "Biesenthal, ST, Germany",
#       point:              {
#         type:               "Point",
#         coordinates:        [52.74197006225586, 11.557829856872559]},
#       address:            {
#         adminDistrict:      "ST",
#         adminDistrict2:     "Stendal",
#         countryRegion:      "Germany",
#         formattedAddress:   "Biesenthal, ST, Germany",
#         locality:           "Biesenthal"},
#       confidence:         "Medium",
#       entityType:         "PopulatedPlace",
#       geocodePoints:      [{
#           type:               "Point",
#           coordinates:        [52.74197006225586, 11.557829856872559],
#           calculationMethod:  "Rooftop",
#           usageTypes:         ["Display"]}],
#       matchCodes:         ["Ambiguous", "Good"]}, @cache_hit=false>]]
