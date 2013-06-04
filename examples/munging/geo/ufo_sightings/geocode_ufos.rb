#!/usr/bin/env ruby
require_relative './common'

require_relative './monkeypatch_geocoder'

Settings.use :commandline
Settings.define :email,              description: "Your email address (for Nominatim)"
Settings.read '~/.configliere/geocoder.yaml'
Settings.resolve!

Geocoder.configure(cache: Redis.new, timeout: 8)

puts("# -*- encoding: utf-8 -*-\nLOCATIONS_MAPPING = {")
Pathname.of(:ufo_rawd, 'locations.tsv').open do |locations_file|
  locations_file.readlines[0..-1].each do |location|
    begin
      location.chomp!
      if location =~ /^(.*)\s+\((.*)\),(.*)$/
        lookup_location = $3.present? ? "#{$1}, #{$3}, #{$2}" : "#{$1}, #{$2}"
      else
        lookup_location = location
      end
      Geocoder.batch do |provider|
        result = Geocoder.search(lookup_location)
        if result.blank? then
          # Log.debug ["---", provider, location[0..40]].join("\t") ;
          next ; end
        #
        place = RawGeocoderPlace.receive_result(result.first)
        puts ["  %-50s" % location.inspect, "=>", place.to_wire.compact.inspect+","].join(" ")
        # puts [(result.cache_hit ? "c  " : "   "), provider, location[0..40], place.to_dumpable].join("\t")
        #
        sleep 2 if (provider == :nominatim) && (not result.cache_hit)
      end
    rescue Errno::EHOSTUNREACH, StandardError => err
      warn [err, err.backtrace].flatten.join("\n")
      3.times{ puts '' }
      sleep 10
    end
  end
end
puts("}")
