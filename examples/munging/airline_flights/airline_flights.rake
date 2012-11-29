require_relative('../../rake_helper')
require_relative('./models')

Pathname.register_paths(
  af_data:                  [:data, 'airline_flights'],
  af_work:                  [:work, 'airline_flights'],
  af_code:                  File.dirname(__FILE__),
  #
  openflights_raw_airports: [:af_data, "openflights_airports-raw#{Settings[:mini_slug]}.csv"   ],
  openflights_raw_airlines: [:af_data, "openflights_airlines-raw.csv"   ],
  dataexpo_raw_airports:    [:af_data, "dataexpo_airports-raw#{Settings[:mini_slug]}.csv"      ],
  wikipedia_icao:           [:af_data, "wikipedia_icao.tsv" ],
  wikipedia_iata:           [:af_data, "wikipedia_iata.tsv" ],
  wikipedia_us_abroad:      [:af_data, "wikipedia_us_abroad.tsv" ],
  #
  openflights_airports:     [:af_work, "openflights_airports-parsed#{Settings[:mini_slug]}.tsv"],
  openflights_airlines:     [:af_work, "openflights_airlines-parsed#{Settings[:mini_slug]}.tsv"],
  dataexpo_airports:        [:af_work, "dataexpo_airports-parsed#{Settings[:mini_slug]}.tsv"   ],
  airport_identifiers:      [:af_work, "airport_identifiers.tsv"   ],
  airport_identifiers_mini: [:af_work, "airport_identifiers-sample.tsv"   ],
  # helpers
  country_name_lookup:       [:work, 'geo', "country_name_lookup.tsv"],
  )

chain :airline_flights do
  code_files = FileList[Pathname.of(:af_code, '*.rb').to_s]
  chain(:parse) do

    # desc 'parse the dataexpo airports'
    # create_file(:dataexpo_airports, after: code_files) do |dest|
    #   RawDataexpoAirport.load_airports(:dataexpo_raw_airports) do |airport|
    #     dest << airport.to_tsv << "\n"
    #   end
    # end

    desc 'parse the openflights airports'
    create_file(:openflights_airports, after: [code_files, :force]) do |dest|
      require_relative('../geo/geo_models')
      Geo::CountryNameLookup.load
      RawOpenflightAirport.load_airports(:openflights_raw_airports) do |airport|
        dest << airport.to_tsv << "\n"
        # puts airport.country
      end
    end

    # task :reconcile_airports => [:dataexpo_airports, :openflights_airports] do
    #   require_relative 'reconcile_airports'
    #   Airport::IdReconciler.load_all
    # end
    #
    # desc 'run the identifier reconciler'
    # create_file(:airport_identifiers, after: code_files, invoke: 'airline_flights:parse:reconcile_airports') do |dest|
    #   Airport::IdReconciler.airports.each do |airport|
    #     dest << airport.to_tsv << "\n"
    #   end
    # end
    #
    # desc 'run the identifier reconciler'
    # create_file(:airport_identifiers_mini, after: code_files, invoke: 'airline_flights:parse:reconcile_airports') do |dest|
    #   Airport::IdReconciler.exemplars.each do |airport|
    #     dest << airport.to_tsv << "\n"
    #   end
    # end
    #
    # desc 'parse the openflights airlines'
    # create_file(:openflights_airlines, after: code_files) do |dest|
    #   RawOpenflightAirline.load_airlines(:openflights_raw_airlines) do |airline|
    #     dest << airline.to_tsv << "\n"
    #     puts airline.to_tsv
    #   end
    # end

  end
end

task :default => [
  'airline_flights',
  # 'airline_flights:parse:dataexpo_airports',
  # 'airline_flights:parse:openflights_airports',
  # 'airline_flights:parse:airport_identifiers',
  # 'airline_flights:parse:airport_identifiers_mini',
  # 'airline_flights:parse:openflights_airlines',
]
