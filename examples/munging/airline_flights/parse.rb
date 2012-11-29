
# see alsospec/examples/munging/airline_flights_spec.rb

      puts described_class.field_names.map{|fn| fn[0..6] }.join("\t")
      raw_airports = RawDataexpoAirport.load_csv(de_airports_filename)
      raw_airports.each do |airport|
        puts airport.to_tsv
      end

      puts described_class.field_names.join("\t") # .map{|fn| fn[0..6] }.join("\t")
      raw_airports = described_class.load_csv(raw_airports_filename)
      raw_airports.each do |airport|
        # puts airport.to_tsv
        linted = airport.lint
        puts [airport.iata, airport.icao, linted.inspect, airport.to_tsv, ].join("\t") if linted.present?
      end

      Airport.load(raw_airports_filename, de_airports_filename)
      Airport::AIRPORTS.each{|id,airport|
        #puts airport.to_tsv
        linted = airport.lint
        warn [airport.iata, airport.icao, airport.de_iata, "%-25s" % airport.name, linted.inspect].join("\t") if linted.present?
      }


# Model.from_tuple(...)
