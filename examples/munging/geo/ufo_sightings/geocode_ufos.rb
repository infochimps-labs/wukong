#!/usr/bin/env ruby
require_relative './common'

require_relative './monkeypatch_geocoder'

Settings.use :commandline
Settings.define :email,              description: "Your email address (for Nominatim)"
Settings.read '~/.configliere/geocoder.yaml'
Settings.resolve!

Geocoder.configure(cache: Redis.new, timeout: 5)

Pathname.of(:ufo_rawd, 'locations.tsv').open do |locations_file|
  locations_file.readlines.each do |location|
    location.chomp!
    if location =~ /^(.*)\s+\((.*)\),(.*)$/
      location = $3.present? ? "#{$1}, #{$3}, #{$2}" : "#{$1}, #{$2}"
    end
    Geocoder.batch do |provider|
      result = Geocoder.search(location)
      next unless result.first.present?
      place = RawGeocoderPlace.receive_result(result.first)
      puts [provider, location[0..40], place.to_wire].join("\t")
      sleep 1 if (provider == :nominatim) && (not result.cache_hit)
    end
  end
end
