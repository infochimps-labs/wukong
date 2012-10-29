

# As of January 2012, the OpenFlights/Airline Route Mapper Route Database
# contains 59036 routes between 3209 airports on 531 airlines [spanning the
# globe](http://openflights.org/demo/openflights-routedb-2048.png).  If you
# enjoy this data, please consider [visiting their page and
# donating](http://openflights.org/data.html)
#
# > Notes: Routes are directional: if an airline operates services from A to B
# > and from B to A, both A-B and B-A are listed separately. Routes where one
# > carrier operates both its own and codeshare flights are listed only once.
#
# Sample entries
#
#     BA,1355,SIN,3316,LHR,507,,0,744 777
#     BA,1355,SIN,3316,MEL,3339,Y,0,744
#     TOM,5013,ACE,1055,BFS,465,,0,320
#
class RawOpenflightRoute
  include Gorillib::Model

  field :iataicao,              String,   doc: "2-letter (IATA) or 3-letter (ICAO) code of the airline."
  field :airline_ofid,          Integer,  doc: "Unique OpenFlights identifier for airline (see Airline)."
  field :from_airport_iataicao, String,   doc: "3-letter (IATA) or 4-letter (ICAO) code of the source airport."
  field :from_airport_ofid,     Integer,  doc: "Unique OpenFlights identifier for source airport (see Airport)"
  field :into_airport_iataicao, String,   doc: "3-letter (IATA) or 4-letter (ICAO) code of the destination airport."
  field :into_airport_ofid,     Integer,  doc: "Unique OpenFlights identifier for destination airport (see Airport)"
  field :codeshare,             :boolean, doc: "true if this flight is a codeshare (that is, not operated by Airline, but another carrier); empty otherwise."
  field :stops,                 Integer,  doc: "Number of stops on this flight, or '0' for direct"
  field :equipment_list,        String,   doc: "3-letter codes for plane type(s) generally used on this flight, separated by spaces"

  def receive_codeshare(val)
    super(case val when "Y" then true when "N" then false else val ; end)
  end
end
