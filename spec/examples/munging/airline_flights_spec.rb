require 'spec_helper'
require 'wukong'
require 'gorillib/datetime/parse'

load Pathname.path_to(:examples, 'munging/airline_flights/models.rb')

describe 'Airline Flight Delays Dataset' do
  let(:example_tuple    ){ ["2007", "1",  "1", "1", "1232", "1225", "1341", "1340", "WN", "2891",   "N351", "69",  "75", "54",  "1",  "7", "SMF", "ONT", "389", "4", "11", "0", "",  "0", "0", "0", "0", "0", "0"] }
  let(:cancelled_tuple_a){ ["2007", "1",  "1", "1",   "NA", "2030",   "NA", "2135", "WN", "2734",      "0", "NA",  "65", "NA", "NA", "NA", "SNA", "LAS", "226", "0",  "0", "1", "A", "0", "0", "0", "0", "0", "0"] }
  let(:cancelled_tuple_c){ ["2007", "1",  "4", "4",   "NA", "2120",   "NA", "2125", "WN", "1631",      "0", "NA",  "65", "NA", "NA", "NA", "PHX", "SAN", "304", "0",  "0", "1", "C", "0", "0", "0", "0", "0", "0"] }
  let(:diverted_tuple   ){ ["2007", "1", "12", "5", "1054", "1054",   "NA", "1209", "EV", "4351", "N857AS", "NA", "135", "NA", "NA",  "0", "ATL", "TUL", "674", "0", "11", "0", "",  "1", "0", "0", "0", "0", "0"] }

  let(:raw_flight         ){ RawAirlineFlight.from_tuple(*example_tuple)     }
  let(:raw_cancelled      ){ RawAirlineFlight.from_tuple(*cancelled_tuple_a) }
  let(:raw_diverted       ){ RawAirlineFlight.from_tuple(*diverted_tuple)    }
  let(:example_flight     ){ raw_flight.to_airline_flight                    }
  let(:cancelled_flight   ){ raw_cancelled.to_airline_flight              }
  let(:diverted_flight    ){ raw_diverted.to_airline_flight               }

  let(:de_airports_filename   ){ Pathname.path_to(:data, 'airline_flights/dataexpo_airports-raw.csv') }

  let(:raw_airports_filename  ){ Pathname.path_to(:data, 'airline_flights/openflights_airports-raw.csv') }
  let(:raw_airlines_filename  ){ Pathname.path_to(:data, 'airline_flights/openflights_airlines-raw-sample.csv') }

  let(:example_flight_attrs) { {
      flight_datestr: '20070101', unique_carrier: "WN", flight_num: 2891,
      from_airport: "SMF", into_airport: "ONT", tail_num: "N351", distance_km: 626, day_of_week: 1,
      crs_dep_itime:  1167654300, crs_arr_itime: 1167658800,
      act_dep_itime:  1167654720, act_arr_itime: 1167658860,
      crs_dep_tod:    "1225",   crs_arr_tod: "1340",
      act_dep_tod:    "1232",   act_arr_tod: "1341",
      crs_duration:   75, act_duration: 69, air_duration: 54, taxi_in_duration: 4, taxi_out_duration: 11,
      is_diverted: false, is_cancelled: false, cancellation_code: "Z",
      dep_delay: 7, arr_delay: 1, carrier_delay: 0, weather_delay: 0, nas_delay: 0, security_delay: 0, late_aircraft_delay: 0,
    } }

  describe RawAirlineFlight do
    subject{ raw_flight }
  
    it 'loads from a hash' do
      p subject.compact_attributes
      subject.compact_attributes.should == {
        date_year:  2007, date_month: 1, date_day: 1, day_of_week: 1,
        act_arr_tod: "1341",         act_dep_tod: "1232",
        crs_arr_tod: "1340",         crs_dep_tod: "1225",
        # act_arr_itime: 1167658860, act_dep_itime: 1167654720,
        # crs_arr_itime: 1167658800, crs_dep_itime: 1167654300,
        unique_carrier: "WN", flight_num: 2891, tail_num: "N351",
        act_duration: 69, crs_duration: 75, air_duration: 54, arr_delay: 1, dep_delay: 7,
        from_airport: "SMF", into_airport: "ONT", distance_mi: 389, taxi_in_duration: 4, taxi_out_duration: 11,
        is_cancelled: false, cancellation_code: "Z", is_diverted: false,
        carrier_delay: 0, weather_delay: 0, nas_delay: 0, security_delay: 0, late_aircraft_delay: 0,
      }
    end
  
    it 'loads cancelled flights OK' do
      # ff = RawAirlineFlight.fields[:act_dep_itime].type
      flight = described_class.from_tuple(*cancelled_tuple_a)
      p flight.compact_attributes
      flight.compact_attributes.should == {
        date_year:  2007, date_month: 1, date_day: 1, day_of_week: 1,
        act_arr_tod: nil,            act_dep_tod: nil,
        crs_arr_tod: "2135",         crs_dep_tod: "2030",
        # act_arr_itime: nil,        act_dep_itime: nil,
        # crs_arr_itime: 1167687300, crs_dep_itime: 1167683400,
        unique_carrier: "WN", flight_num: 2734,  tail_num: nil,
        act_duration: nil, crs_duration: 65, air_duration: nil, arr_delay: nil, dep_delay: nil,
        from_airport: "SNA", into_airport: "LAS", distance_mi: 226, taxi_in_duration: 0, taxi_out_duration: 0,
        is_cancelled: true, cancellation_code: "A", is_diverted: false,
        carrier_delay: 0, weather_delay: 0, nas_delay: 0, security_delay: 0, late_aircraft_delay: 0,
      }
    end
  
    it 'loads diverted flights OK' do
      # ff = RawAirlineFlight.fields[:act_dep_itime].type
      flight = described_class.from_tuple(*diverted_tuple)
      p flight.compact_attributes
      flight.compact_attributes.should == {
        date_year:  2007, date_month: 1, date_day: 12, day_of_week: 5,
        act_arr_tod: nil,            act_dep_tod: "1054",
        crs_arr_tod: "1209",         crs_dep_tod: "1054",
        # act_arr_itime: nil,        act_dep_itime: 1168599240,
        # crs_arr_itime: 1168603740, crs_dep_itime: 1168599240,
        unique_carrier: "EV", flight_num: 4351, tail_num: "N857AS",
        act_duration: nil, crs_duration: 135, air_duration: nil, arr_delay: nil, dep_delay: 0,
        from_airport: "ATL", into_airport: "TUL", distance_mi: 674, taxi_in_duration: 0, taxi_out_duration: 11,
        is_cancelled: false, cancellation_code: "Z", is_diverted: true,
        carrier_delay: 0, weather_delay: 0, nas_delay: 0, security_delay: 0, late_aircraft_delay: 0,
      }
    end
  
    it 'does dates right' do
      { normal:    [example_tuple,     raw_flight],
        cancelled: [cancelled_tuple_a, raw_cancelled],
        diverted:  [diverted_tuple,    raw_diverted],
      }.each do |label, (raw_values, raw_flight)|
        [ [raw_flight.act_dep_itime, raw_values[4] ],
          [raw_flight.crs_dep_itime, raw_values[5] ],
          [raw_flight.act_arr_itime, raw_values[6] ],
          [raw_flight.crs_arr_itime, raw_values[7] ],
        ].each do |itime, hhmm|
          next unless itime
          tm = Time.at(itime).utc
          (tm.hour * 100 + tm.min).to_s.should == hhmm
        end
      end
    end
  
    it 'receives idempotently' do
      subject.should == RawAirlineFlight.receive(subject.compact_attributes)
    end
  
    it '#to_airline_flight' do
      flight = subject.to_airline_flight
      flight.should be_a(AirlineFlight)
      flight.compact_attributes.should == example_flight_attrs
    end
  end
  
  describe AirlineFlight do
    subject{ example_flight }
  
    it "makes sense" do
      { normal: example_flight, cancelled: cancelled_flight, diverted: diverted_flight
      }.each do |label, flight|
        linted = subject.lint
        p [label, linted, flight] unless linted.values.all?
        linted.values.should be_all
      end
    end
  
    it 'has correct field alignment' do
      described_class.field_names.should == example_flight_attrs.keys
      described_class.fields.values.map(&:position).should == (0..30).to_a
    end

    it 'calculates local times correctly' do
      Airport.load(raw_airports_filename)
      Airport::AIRPORTS.each{|id,airport| puts airport.to_tsv }
    end
  
  end
  
  describe 'parsing raw' do
    it 'works' do
      raw_file = File.open(raw_airlines_filename)
      raw_file.readline
      puts AirlineFlight.field_names.map{|fn| fn[0..6] }.join("\t")
      raw_file.each do |line|
        tuple = line.split(',')
        # next unless tuple[23] == "1"
        raw_flight = RawAirlineFlight.from_tuple(*tuple)
        flight = raw_flight.to_airline_flight
        # if not flight.lint.values.all?
          # p flight.lint.values
          puts flight.to_tsv
          # p [
          #   [raw_flight.crs_dep_itime, tuple[5] ],
          #   [raw_flight.crs_arr_itime, tuple[7] ],
          #   (raw_flight.crs_arr_itime - raw_flight.crs_arr_itime),
          #   (raw_flight.crs_arr_itime - raw_flight.crs_dep_itime)/60.0,
          #   raw_flight.crs_duration
          # ]
        # end
      end
    end
  end

  describe RawDataexpoAirport do
    it 'works' do
      puts described_class.field_names.map{|fn| fn[0..6] }.join("\t")
      raw_airports = RawDataexpoAirport.load_csv(de_airports_filename)
      raw_airports.each do |airport|
        puts airport.to_tsv
      end
    end
  end

  describe RawOpenflightAirport do
    it 'works' do
      puts described_class.field_names.join("\t") # .map{|fn| fn[0..6] }.join("\t")
      raw_airports = described_class.load_csv(raw_airports_filename)
      raw_airports.each do |airport|
        # puts airport.to_tsv
        linted = airport.lint
        puts [airport.iata, airport.icao, linted.inspect, airport.to_tsv, ].join("\t") if linted.present?
      end
    end
  end
  
  describe Airport do
    it 'loads and reconciles' do
      Airport.load(raw_airports_filename, de_airports_filename)
      Airport::AIRPORTS.each{|id,airport|
        #puts airport.to_tsv
        linted = airport.lint
        warn [airport.iata, airport.icao, airport.de_iata, "%-25s" % airport.name, linted.inspect].join("\t") if linted.present?
      }
    end
  end

end
