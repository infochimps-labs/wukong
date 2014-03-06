#!/usr/bin/env ruby
require('rake')
require_relative('../../rake_helper')
require_relative './models'

Pathname.register_paths(
  af_data:                  [:data, 'airline_flights'],
  af_work:                  [:work, 'airline_flights'],
  af_code:                  File.dirname(__FILE__),
  airport_identifiers:      [:af_work, "airport_identifiers.tsv"   ],
  )

AIRPORTS_TO_MATCH = [
  [ 'Tokyo',              1, "HND", ],
  [ 'Guangzhou',          2, "CAN", ],
  [ 'Seoul',              3, "ICN", ],
  [ 'Shanghai',           4, "PVG", ],
  [ 'Mexico.*City',       5, "MEX", ],
  [ 'Delhi',              6, "DEL", ],
  [ 'New.*York',          7, "JFK", ],
  [ 'S.*o.*Paulo',        8, "GRU", ],
  [ 'Mumbai|Bombay',      9, "BOM", ],
  [ 'Manila',            10, "MNL", ],
  [ 'Jakarta',           11, "CGK", ],
  [ 'Los.*Angeles',      12, "LAX", ],
  [ 'Karachi',           13, "KHI", ],
  [ 'Osaka',             14, "KIX", ],
  [ 'Beijing',           15, "PEK", ],
  [ 'Moscow',            16, "SVO", ],
  [ 'Cairo',             17, "CAI", ],
  [ 'Kolkata|Calcutta',  18, "CCU", ],
  [ 'Buenos.*Aires',     19, "EZE", ],
  [ 'Dhaka',             20, "DAC", ],
  [ 'Bangkok',           21, "BKK", ],
  [ 'Tehran|Abyek',      22, "IKA", ],
  [ 'Istanbul',          23, "IST", ],
  [ 'Janeiro',           24, "GIG", ],
  [ 'London',            25, "LHR", ],
  [ 'Lagos',             26, "LOS", ],
  [ 'Paris',             27, "CDG", ],
  [ 'Chicago',           28, "ORD", ],
  [ 'Kinshasa',          29, "FIH", ],
  [ 'Lima',              30, "LIM", ],
  [ 'Wuhan',             31, "WUH", ],
  [ 'Bangalore',         32, "BLR", ],
  [ 'Bogot.*',           33, "BOG", ],
  [ 'Taipei',            34, "TSA", ],
  [ 'Washington|Arling', 35, "DCA", ],
  [ 'Johannesburg',      36, "JNB", ],
  [ 'Saigon|Ho.Chi.M',   37, "SGN", ],
  [ 'San.*Francisco',    38, "SFO", ],
  [ 'Boston',            39, "BOS", ],
  [ 'Hong.*Kong',        40, "HKG", ],
  [ 'Baghdad',           41, "SDA", ],
  [ 'Madrid',            42, "MAD", ],
  [ 'Singapore',         43, "SIN", ],
  [ 'Kuala.*Lumpur',     44, "KUL", ],
  [ 'Chongqing|Chung.*', 45, "CKG", ],
  [ 'Santiago',          46, "SCL", ],
  [ 'Toronto',           47, "YYZ", ],
  [ 'Riyadh',            48, "RUH", ],
  [ 'Atlanta',           49, "ATL", ],
  [ 'Miami',             50, "MIA", ],
  [ 'Detroit',           51, "DTW", ],
  [ 'St..*Petersburg',   52, "LED", ],
  [ 'Khartoum',          53, "KRT", ],
  [ 'Sydney',            54, "SYD", ],
  [ 'Milan',             55, "MXP", ],
  [ 'Abidjan',           56, "ABJ", ],
  [ 'Barcelona',         57, "BCN", ],
  [ 'Nairobi',           58, "NBO", ],
  [ 'Caracas',           59, "CCS", ],
  [ 'Monterrey',         60, "MTY", ],
  [ 'Phoenix',           61, "PHX", ],
  [ 'Berlin',            62, "TXL", ],
  [ 'Melbourne',         63, "MEL", ],
  [ 'Casablanca',        64, "CMN", ],
  [ 'Montreal',          65, "YUL", ],
  [ 'Salvador',          66, "SSA", ],
  [ 'Rome',              67, "FCO", ],
  [ 'Kiev',              68, "KBP", ],
  [ 'Ad+is.*Ab.ba',      69, "ADD", ],
  [ 'Denver',            70, "DEN", ],
  [ 'St.*Louis',         71, "STL", ],
  [ 'Dakar',             72, "DKR", ],
  [ 'San.*Juan',         73, "SJU", ],
  [ 'Vancouver',         74, "YVR", ],
  [ 'Tel.*Aviv',         75, "TLV", ],
  [ 'Tunis',             76, "TUN", ],
  [ 'Portland',          77, "PDX", ],
  [ 'Manaus',            78, "MAO", ],
  [ 'Calgary',           79, "YYC", ],
  [ 'Halifax',           80, "YHZ", ],
  [ 'Prague',            81, "PRG", ],
  [ 'Copenhagen',        82, "CPH", ],
  [ 'Djibouti',          83, "JIB", ],
  [ 'Quito',             84, "UIO", ],
  [ 'Helsinki',          85, "HEL", ],
  [ 'Papeete|Tahiti',    86, "PPT", ],
  [ 'Frankfurt',         87, "FRA", ],
  [ 'Reykjavik',         88, "RKV", ],
  [ 'Riga',              89, "RIX", ],
  [ 'Antananarivo',      90, "TNR", ],
  [ 'Amsterdam',         91, "AMS", ],
  [ 'Bucharest',         92, "OTP", ],
  [ 'Novosibirsk',       93, "OVB", ],
  [ 'Kigali',            94, "KGL", ],
  [ 'Dushanbe',          95, "DYU", ],
  [ 'Dubai',             96, "DXB", ],
  [ 'Bermuda',           97, "BDA", ],
  [ 'Anchorage',         98, "ANC", ],
  [ 'Austin',            99, "AUS", ],
  [ 'Honolulu',         100, "HNL", ],
  [ 'Apia',             101, "FGI", ],
  [ 'Vienna',           102, "VIE", ],
  [ 'Brussels',         103, "BRU", ],
  [ 'Munich',           104, "MUC", ],
  [ 'Dublin',           105, "DUB", ],
  [ 'Doha',             106, "DOH", ],
  [ 'Taipei',           107, "TPE", ],
  [ 'Yakutsk',          108, "YKS", ],
  [ 'Z.rich',           109, "ZRH", ],
  [ 'Manchester',       110, "MAN", ],
  [ 'Houston',          111, "IAH", ],
  [ 'Charlotte',        112, "CLT", ],
  [ 'Dallas',           113, "DFW", ],
  [ 'Las.*Vegas',       114, "LAS", ],
  [ 'Antalya',          115, "AYT", ],
  [ 'Auckland',         116, "AKL", ],
]

MATCHED_AIRPORTS = {}
MATCH_ON_IATA = {}
MATCH_ON_CITY = {}
match_on_city_names = []

AIRPORTS_TO_MATCH.each do |name, idx, iata|
  hsh = {iata: iata, re: Regexp.new(name, 'i'), name: name, idx: idx}
  if iata.present?
    MATCH_ON_IATA[iata] = hsh
  else
    match_on_city_names << name
    MATCH_ON_CITY[hsh[:re]] = hsh
  end
end
match_on_city_re = Regexp.new(match_on_city_names.join('|'))

Airport.load_tsv(:airport_identifiers) do |airport|
  airport.name = airport.name[0..30]
  if   MATCH_ON_IATA.include?(airport.iata)
    hsh = MATCH_ON_IATA[airport.iata]
    warn [hsh.values, airport.to_tsv].flatten.join("\t") unless hsh[:re] =~ airport.city
    MATCHED_AIRPORTS[hsh[:idx]] = airport
  # elsif (airport.city =~ match_on_city_re)
  #   MATCH_ON_CITY.each do |re, hsh|
  #     if (airport.city =~ re)
  #       puts [airport.to_tsv, hsh[:name], hsh[:idx]].join("\t")
  #     end
  #   end
  end
end

AIRPORTS_TO_MATCH.each do |name, idx, iata|
  # next if MATCHED_AIRPORTS[idx]
  airport_str = MATCHED_AIRPORTS[idx] ? MATCHED_AIRPORTS[idx].to_tsv : "\t\t\t\t\t\t\t\t\t\t\t\t"
  puts [airport_str, name, "", idx].join("\t")
end
