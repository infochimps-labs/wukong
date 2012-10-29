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

  field :airline_ofid, Integer,  doc: "Unique OpenFlights identifier for this airline."
  field :name,         String,   doc: "Airline name."
  field :alias,        String,   doc: "Alias of the airline. For example, 'All Nippon Airways' is commonly known as 'ANA'"
  field :iata_id,      String,   doc: "2-letter IATA code, if available"
  field :icao_id,      String,   doc: "3-letter ICAO code, if available"
  field :callsign,     String,   doc: "Airline callsign"
  field :country,      String,   doc: "Country or territory where airline is incorporated"
  field :active,       :boolean, doc: 'true if the airline is or has until recently been operational, false if it is defunct. (This is only a rough indication and should not be taken as 100% accurate)'

  def receive_active(val)
    super(case val when "Y" then true when "N" then false else val ; end)
  end

  def to_airline
    Airline.receive(self.compact_attributes)
  end
end

class Airline
  include Gorillib::Model
  field :iata_id,      String,   doc: "2-letter IATA code, if available"
  field :icao_id,      String,   doc: "3-letter ICAO code, if available"
  field :airline_ofid, Integer,  doc: "Unique OpenFlights identifier for this airline."
  field :alias,        String,   doc: "Alias of the airline. For example, 'All Nippon Airways' is commonly known as 'ANA'"
  field :callsign,     String,   doc: "Airline callsign"
  field :country,      String,   doc: "Country or territory where airline is incorporated"
  field :active,       :boolean, doc: 'true if the airline is or has until recently been operational, false if it is defunct. (This is only a rough indication and should not be taken as 100% accurate)'
  field :name,         String,   doc: "Airline name."
end
