class Airline
  include Gorillib::Model
  field :icao_id,      String,   doc: "3-letter ICAO code, if available", identifier: true, length: 2
  field :iata_id,      String,   doc: "2-letter IATA code, if available", identifier: true, length: 2
  field :airline_ofid, Integer,  doc: "Unique OpenFlights identifier for this airline.", identifier: true
  field :active,       :boolean, doc: 'true if the airline is or has until recently been operational, false if it is defunct. (This is only a rough indication and should not be taken as 100% accurate)'
  field :country,      String,   doc: "Country or territory where airline is incorporated"
  field :name,         String,   doc: "Airline name."
  field :callsign,     String,   doc: "Airline callsign", identifier: true
  field :alias,        String,   doc: "Alias of the airline. For example, 'All Nippon Airways' is commonly known as 'ANA'"
end

#
# As of January 2012, the OpenFlights Airlines Database contains 5888
# airlines. If you enjoy this data, please consider [visiting their page and
# donating](http://openflights.org/data.html)
#
# > Notes: Airlines with null codes/callsigns/countries generally represent
# > user-added airlines. Since the data is intended primarily for current
# > flights, defunct IATA codes are generally not included. For example,
# > "Sabena" is not listed with a SN IATA code, since "SN" is presently used by
# > its successor Brussels Airlines.
#
# Sample entries
#
#     324,"All Nippon Airways","ANA All Nippon Airways","NH","ANA","ALL NIPPON","Japan","Y"
#     412,"Aerolineas Argentinas",\N,"AR","ARG","ARGENTINA","Argentina","Y"
#     413,"Arrowhead Airways",\N,"","ARH","ARROWHEAD","United States","N"
#
class RawOpenflightAirline
  include Gorillib::Model
  include Gorillib::Model::LoadFromCsv
  BLANKISH_STRINGS = ["", nil, "NULL", '\\N', "NONE", "NA", "Null", "..."]

  field :airline_ofid, Integer,  blankish: BLANKISH_STRINGS, doc: "Unique OpenFlights identifier for this airline.", identifier: true
  field :name,         String,   blankish: BLANKISH_STRINGS, doc: "Airline name."
  field :alias,        String,   blankish: BLANKISH_STRINGS, doc: "Alias of the airline. For example, 'All Nippon Airways' is commonly known as 'ANA'"
  field :iata_id,      String,   blankish: BLANKISH_STRINGS, doc: "2-letter IATA code, if available", identifier: true, length: 2
  field :icao_id,      String,   blankish: BLANKISH_STRINGS, doc: "3-letter ICAO code, if available", identifier: true, length: 2
  field :callsign,     String,   blankish: BLANKISH_STRINGS, doc: "Airline callsign"
  field :country,      String,   blankish: BLANKISH_STRINGS, doc: "Country or territory where airline is incorporated"
  field :active,       :boolean, blankish: BLANKISH_STRINGS, doc: 'true if the airline is or has until recently been operational, false if it is defunct. (This is only a rough indication and should not be taken as 100% accurate)'

  def receive_iata_id(val) super if val =~ /\A\w+\z/ ; end
  def receive_icao_id(val) super if val =~ /\A\w+\z/ ; end
  def receive_active(val)
    super(case val.to_s when "Y" then true when "N" then false else val ; end)
  end

  def to_airline
    Airline.receive(self.compact_attributes)
  end

  def self.load_airlines(filename)
    load_csv(filename){|raw_airline| yield(raw_airline.to_airline) }
  end
end
