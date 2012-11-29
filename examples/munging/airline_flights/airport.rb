# -*- coding: utf-8 -*-

### @export "airport_model"
class Airport
  include Gorillib::Model

  field :icao,         String, doc: "4-letter ICAO code, or blank if not assigned.", length: 4, identifier: true, :blankish => ["", nil]
  field :iata,         String, doc: "3-letter IATA code, or blank if not assigned.", length: 3, identifier: true, :blankish => ["", nil]
  field :faa,          String, doc: "3-letter FAA code, or blank if not assigned.",  length: 3, identifier: true, :blankish => ["", nil]
  field :utc_offset,   Float,  doc: "Hours offset from UTC. Fractional hours are expressed as decimals, eg. India is 5.5.",      validates: {  inclusion: (-12...12) }
  field :dst_rule,     String, doc: "Daylight savings time rule. One of E (Europe), A (US/Canada), S (South America), O (Australia), Z (New Zealand), N (None) or U (Unknown). See the readme for more.", validates: {  inclusion: %w[E A S O Z N U] }
  field :longitude,    Float,  doc: "Decimal degrees, usually to six significant digits. Negative is West,  positive is East.",  validates: {  inclusion: (-180...180) }
  field :latitude,     Float,  doc: "Decimal degrees, usually to six significant digits. Negative is South, positive is North.", validates: {  inclusion: (-90.0...90.0) }
  field :altitude,     Float,  doc: "Elevation in meters."
  field :name,         String, doc: "Name of airport."
  field :country,      String, doc: "Country or territory where airport is located.", length: 2
  field :state,        String, doc: "State in which the airport is located",          length: 2
  field :city,         String, doc: "Main city served by airport. This is the logical city it serves; so, for example SFO gets 'San Francisco', not 'San Bruno'"
  field :airport_ofid, String, doc: "OpenFlights identifier for this airport.", identifier: true
end
### @export "nil"
class Airport
  EXEMPLARS = %w[
    ANC ATL AUS BDL BNA BOI BOS BWI CLE CLT
    CMH DCA DEN DFW DTW EWR FLL HNL IAD IAH
    IND JAX JFK LAS LAX LGA MCI MCO MDW MIA
    MSP MSY OAK ORD PDX PHL PHX PIT PVD RDU
    SAN SEA SFO SJC SJU SLC SMF STL TPA YYZ
  ]

  def utc_time_for(tm)
    utc_time  = tm.get_utc + utc_offset
    utc_time += (60*60) if TimezoneFixup.dst?(tm)
    utc_time
  end

  BLANKISH_STRINGS = ["", nil, "NULL", '\\N', "NONE", "NA", "Null", "..."]
  OK_CHARS_RE      = /[^a-zA-Z0-9\:\ \/\.\,\-\(\)\'ÁÂÄÅÇÉÍÎÑÓÖØÚÜÞàáâãäåæçèéêëìíîïðñóôõöøúüýĀāăĆćČčēėęěğīİıŁłńņňŌōőřŞşŠšţťūůųźŽžơț]/

  def lint
    errors = {}
    errors["ICAO is wrong length"] = icao if icao.present? && icao.length != 4
    if (icao && faa && (icao =~ /^K.../))
      errors["ICAO != K+FAA yet ICAO is a K..."] = [icao, faa] if (icao != "K#{faa}")
    end
    # errors["ICAO present for piddlyshit airport"] = icao if icao.present? && ((faa.to_s.length == 4) || (faa.to_s =~ /\d/))
    errors[:spaces] ||= []
    errors[:funny]  ||= []
    attributes.each do |attr, val|
      next if val.blank?
      errors["#{attr} looks blankish"] = val if BLANKISH_STRINGS.include?(val)
      if (val.is_a?(String))
        errors[:spaces] << [attr, val] if  (val.strip != val)
        errors[:funny]  << [attr, val]  if val =~ OK_CHARS_RE
      end
    end
    errors.compact_blank
  end

  def to_s
    str = "#<Airport "
    str << [icao, iata, faa,
      (latitude && "%4.1f" % latitude), (longitude && "%5.1f" % longitude), state, country,
      "%-30s" % name, country, city].join("\t")
    str << ">"
  end

  def faa_controlled?
    icao =~ /^(?:K|P[ABFGHJKMOPW]|T[IJ]|NS(AS|FQ|TU))/
  end
end
### @export "airport_load"
class Airport
  include Gorillib::Model::LoadFromTsv
  self.tsv_options.merge!(num_fields: 10..20)
  def self.load_airports(filename)
    load_tsv(filename){|airport| yield(airport) }
  end

end
### @export "nil"

#
# As of January 2012, the OpenFlights Airports Database contains 6977 airports
# [spanning the globe](http://openflights.org/demo/openflights-apdb-2048.png).
# If you enjoy this data, please consider [visiting their page and
# donating](http://openflights.org/data.html)
#
# > Note: Rules for daylight savings time change from year to year and from
# > country to country. The current data is an approximation for 2009, built on
# > a country level. Most airports in DST-less regions in countries that
# > generally observe DST (eg. AL, HI in the USA, NT, QL in Australia, parts of
# > Canada) are marked incorrectly.
#
# Sample entries
#
#     507,"Heathrow","London","United Kingdom","LHR","EGLL",51.4775,-0.461389,83,0,"E"
#     26,"Kugaaruk","Pelly Bay","Canada","YBB","CYBB",68.534444,-89.808056,56,-6,"A"
#     3127,"Pokhara","Pokhara","Nepal","PKR","VNPK",28.200881,83.982056,2712,5.75,"N"
#

### @export "raw_openflight_airport"

module RawAirport
  COUNTRIES        = { 'Puerto Rico' => 'us', 'Canada' => 'ca', 'USA' => 'us', 'United States' => 'us',
    'Northern Mariana Islands' => 'us', 'N Mariana Islands' => 'us',
    'Federated States of Micronesia' => 'fm',
    'Thailand' => 'th', 'Palau' => 'pw',
    'American Samoa' => 'as', 'Wake Island' => 'us', 'Virgin Islands' => 'vi', 'Guam' => 'gu'
  }
  BLANKISH_STRINGS = ["", nil, "NULL", '\\N', "NONE", "NA", "Null", "..."]
  OK_CHARS_RE      = /[^a-zA-Z0-9\:\ \/\.\,\-\(\)\'ÁÂÄÅÇÉÍÎÑÓÖØÚÜÞàáâãäåæçèéêëìíîïðñóôõöøúüýĀāăĆćČčēėęěğīİıŁłńņňŌōőřŞşŠšţťūůųźŽžơț]/

  def receive_city(val)
    super.tap{|val| if val then val.strip! ; val.gsub!(/\\+/, '') ; end }
  end

  def receive_country(val)
    super(COUNTRIES[val] || val)
  end

  def receive_name(val)
    super.tap do |val|
      if val
        val.strip!
        val.gsub!(/\\+/, '')
        val.gsub!(/\s*\[(military|private)\]/, '')
        val.gsub!(/\b(Int\'l|International)\b/, 'Intl')
        val.gsub!(/\b(Intercontinental)\b/,     'Intcntl')
        val.gsub!(/\b(Airpt)\b/,                'Airport')
        val.gsub!(/ Airport$/, '')
      end
    end
  end
end

#
class RawOpenflightAirport
  include Gorillib::Model
  include Gorillib::Model::LoadFromCsv
  include RawAirport
  #
  field :airport_ofid, String, doc: "Unique OpenFlights identifier for this airport."
  field :name,        String, doc: "Name of airport. May or may not contain the City name."
  field :city,        String, blankish: BLANKISH_STRINGS, doc: "Main city served by airport. May be spelled differently from Name."
  field :country,     String, doc: "Country or territory where airport is located."
  field :iata_faa,    String, blankish: BLANKISH_STRINGS, doc: "3-letter FAA code, for airports located in the USA. For all other airports, 3-letter IATA code, or blank if not assigned."
  field :icao,        String, blankish: BLANKISH_STRINGS, doc: "4-letter ICAO code; Blank if not assigned."
  field :latitude,    Float,  doc: "Decimal degrees, usually to six significant digits. Negative is South, positive is North."
  field :longitude,   Float,  doc: "Decimal degrees, usually to six significant digits. Negative is West,  positive is East."
  field :altitude_ft, Float,  blankish: ['', nil, 0, '0'], doc: "In feet."
  field :utc_offset,  Float,  doc: "Hours offset from UTC. Fractional hours are expressed as decimals, eg. India is 5.5."
  field :dst_rule,    String, doc: "Daylight savings time rule. One of E (Europe), A (US/Canada), S (South America), O (Australia), Z (New Zealand), N (None) or U (Unknown). See the readme for more."

  UNRELIABLE_OPENFLIGHTS_IATA_VALUES = /^(7AK|AGA|AUQ|BDJ|BGW|BME|BPM|BXH|BZY|CAT|CEE|CEJ|CFS|CGU|CIO|CLV|CNN|DEE|DIB|DNM|DUH|DUR|FKI|GES|GSM|HKV|HOJ|HYD|IEO|IFN|IKA|IZA|JCU|JGS|KMW|KNC|LGQ|LUM|MCU|MCY|MDO|MOH|MON|MPH|MVF|NAY|NMA|NOE|NQY|OTU|OUI|PBV|PCA|PCB|PGK|PHO|PIF|PKN|PKY|PMK|PTG|PZO|QAS|QKT|QVY|RCM|RJL|RTG|SBG|SDZ|SFG|SIC|SIQ|SJI|SRI|STP|STU|SWQ|TJQ|TJS|TMC|TYA|UKC|VIY|VQS|VTS|WDH|WKM|WPR|WPU|ZQF)$/

  def id_is_faa?
    (icao =~ /^(?:K)/) || (icao.blank? && country == 'us')
  end

  def iata ;  (id_is_faa? ? nil      : iata_faa) unless iata_faa =~ UNRELIABLE_OPENFLIGHTS_IATA_VALUES end
  def faa  ;  (id_is_faa? ? iata_faa : nil     ) end
  def altitude
    altitude_ft && (0.3048 * altitude_ft).round(1)
  end

  def receive_country(val)
    country = Geo::CountryNameLookup.for_alt_name(val, nil)
    p val unless country
    super(country ? country.country_id : val)
  end

  def to_airport
    attrs = self.compact_attributes.except(:altitude_ft)
    attrs[:altitude] = altitude
    attrs[:iata]     = iata unless iata.to_s =~ UNRELIABLE_OPENFLIGHTS_IATA_VALUES
    attrs[:faa]      = faa
    Airport.receive(attrs)
  end

  def self.load_airports(filename)
    load_csv(filename){|raw_airport| yield(raw_airport.to_airport) }
  end
end

### @export "raw_dataexpo_airport"
class RawDataexpoAirport
  include Gorillib::Model
  include Gorillib::Model::LoadFromCsv
  include RawAirport
  self.csv_options = self.csv_options.merge(pop_headers: true)

  field :faa,          String, doc: "the international airport abbreviation code"
  field :name,         String, doc: "Airport name"
  field :city,         String, blankish: ["NA"], doc: "city in which the airport is located"
  field :state,        String, blankish: ["NA"], doc: "state in which the airport is located"
  field :country,      String, doc: "country in which airport is located"
  field :latitude,     Float,  doc: "latitude of the airport"
  field :longitude,    Float,  doc: "longitude of the airport"

  def to_airport
    attrs = self.compact_attributes
    attrs[:icao] = "K#{faa}" if faa =~ /[A-Z]{3}/ && (not ['PR', 'AK', 'CQ', 'HI', 'AS', 'GU', 'VI'].include?(state)) && (country == 'us')
    Airport.receive(attrs)
  end

  def self.load_airports(filename)
    load_csv(filename){|raw_airport| yield(raw_airport.to_airport) }
  end
end
### @export "nil"
