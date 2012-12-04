#!/usr/bin/env ruby
require 'wukong'
require 'gorillib/type/ip_address'
require 'gorillib/pathname'
require 'gorillib/model/serialization'
require 'gorillib/model/positional_fields'

Pathname.register_paths(
  maxmind: '../../../data/server_logs/maxmind',
  geolite_ip_blocks: [:maxmind, 'GeoLiteCity_20121002/GeoLiteCity-Blocks.csv'],
  geolite_locations: [:maxmind, 'GeoLiteCity_20121002/GeoLiteCity-Location.csv'],
  )

class IpGeo
  include Gorillib::Model
  include Gorillib::Model::PositionalFields
  #
  field :location_id, Integer
  field :longitude,   Float  # note: longitude, latitude
  field :latitude,    Float
  #
  field :country_id,  String, blankish: ["", nil, '""']
  field :admin1_id,   String, blankish: ["", nil, '""']
  field :city,        String, blankish: ["", nil, '""']
  #
  field :postal_code, String, blankish: ["", nil, '""']
  field :metro_code,  String, blankish: ["", nil, '""']
  field :area_code,   String, blankish: ["", nil, '""']
end

lines = 0
LOCATIONS = {}
locations_file = Pathname.of(:geolite_locations).open(encoding: "ISO-8859-1")
locations_file.readline; locations_file.readline
locations_file.
  # readlines[0..1000].
  each do |line|
  location_id, country_id, admin1_id, city, postal_code, latitude, longitude, metro_code, area_code = line.chomp.gsub(/"/, '').split(',', 9)
  LOCATIONS[location_id.to_i] = [ location_id.to_i, longitude.to_f, latitude.to_f, country_id, admin1_id, city, postal_code, metro_code, area_code ]
end

module IpCensus
  class IpBlocksMapper < Wukong::Streamer::RecordStreamer

    def initialize(*)
      super
      @last = IpNumeric.from_dotted('0.116.0.0')
    end

    def recordize line
      beg_ip, end_ip, location_id = line.gsub(/\"/, '').split(",", 3)
      [IpNumeric.new(Integer(beg_ip)), IpNumeric.new(Integer(end_ip)), Integer(location_id)]
    end

    # Use the regex to break line into fields
    # Emit each record as flat line
    def process(beg_ip, end_ip, location_id, &block)
      emit_range(IpRange.new(@last, beg_ip), 0, &block) if @last != beg_ip.to_int
      emit_range IpRange.new(beg_ip, end_ip), location_id, &block
      @last = end_ip.to_i + 1
    end

    def emit_range(rng, location_id)
      location = LOCATIONS[location_id]
      warn "No location #{location_id.inspect}" unless location || (location_id == 0)
      rng.bitness_blocks(16).each do |blk_min, blk_max|
        # raise [blk_min, blk_max, blk_min.to_hex[0..-5], blk_max.to_hex[0..-5]].inspect if blk_min.to_hex[0..-3] != blk_max.to_hex[0..-3]
        yield [
          blk_min.to_hex[0..3],
          blk_min.to_hex[4..-1],
          blk_max.to_hex[4..-1],
          blk_min.to_i,
          blk_max.to_i,
          location,
        ].flatten
      end
    end

  end
end

Wukong::Script.new(IpCensus::IpBlocksMapper, nil).run
