require 'gorillib/model/factories'

# Raw data:
#   Year,Month,DayofMonth,DayOfWeek,DepTime,CRSDepTime,ArrTime,CRSArrTime,UniqueCarrier,FlightNum,TailNum,ActualElapsedTime,CRSElapsedTime,AirTime,ArrDelay,DepDelay,Origin,Dest,Distance,TaxiIn,TaxiOut,Can
#   2007,1,1,1,1232,1225,1341,1340,WN,2891,N351,69,75,54,1,7,SMF,ONT,389,4,11,0,,0,0,0,0,0,0

class RawAirlineFlight
  include Gorillib::Model

  field :date_year,           Integer,     position:  1, doc: "Year (1987-2008)"
  field :date_month,          Integer,     position:  2, doc: "Month (1-12)"
  field :date_day,            Integer,     position:  3, doc: "Day of month (1-31)"
  field :day_of_week,         Integer,     position:  4, doc: "Day of week -- 1 (Monday) - 7 (Sunday)"
  #
  field :act_dep_tod,         String,      position:  5, doc: "time of day for actual departure (local, hhmm)", blankish: [nil, '', 'NA']
  field :crs_dep_tod,         String,      position:  6, doc: "time of day for scheduled departure (local, hhmm)"
  field :act_arr_tod,         String,      position:  7, doc: "time of day for actual arrival (local, hhmm). Not adjusted for wrap-around.",   blankish: [nil, '', 'NA']
  field :crs_arr_tod,         String,      position:  8, doc: "time of day for scheduled arrival (local, hhmm). Not adjusted for wrap-around."
  #
  field :unique_carrier,      String,     position:  9, doc: "unique carrier code",                 validates: { length: { in: 0..5 } }
  field :flight_num,          Integer,     position: 10, doc: "flight number"
  field :tail_num,            String,      position: 11, doc: "plane tail number",                   validates: { length: { in: 0..8 } }
  #
  field :act_duration,        Integer,     position: 12, doc: "actual flight time, in minutes",      blankish: [nil, '', 'NA']
  field :crs_duration,        Integer,     position: 13, doc: "CRS flight time, in minutes"
  field :air_duration,        Integer,     position: 14, doc: "Air time, in minutes",                blankish: [nil, '', 'NA']
  field :arr_delay,           Integer,     position: 15, doc: "arrival delay, in minutes",           blankish: [nil, '', 'NA']
  field :dep_delay,           Integer,     position: 16, doc: "departure delay, in minutes",         blankish: [nil, '', 'NA']
  field :from_airport,        String,      position: 17, doc: "Origin IATA airport code",            validates: { length: { in: 0..3 } }
  field :into_airport,        String,      position: 18, doc: "Destination IATA airport code",       validates: { length: { in: 0..3 } }
  field :distance_mi,         Integer,     position: 19, doc: "Flight distance, in miles"
  field :taxi_in_duration,    Integer,     position: 20, doc: "taxi in time, in minutes",            blankish: [nil, '', 'NA']
  field :taxi_out_duration,   Integer,     position: 21, doc: "taxi out time in minutes",            blankish: [nil, '', 'NA']
  #
  field :is_cancelled,        :boolean_10, position: 22, doc: "was the flight cancelled?"
  field :cancellation_code,   String,      position: 23, doc: "Reason for cancellation (A = carrier, B = weather, C = NAS, D = security, Z = no cancellation)"
  field :is_diverted,         :boolean_10, position: 24, doc: "Was the plane diverted?"
  field :carrier_delay,       Integer,     position: 25, doc: "in minutes"
  field :weather_delay,       Integer,     position: 26, doc: "in minutes"
  field :nas_delay,           Integer,     position: 27, doc: "in minutes"
  field :security_delay,      Integer,     position: 28, doc: "in minutes"
  field :late_aircraft_delay, Integer,     position: 29, doc: "in minutes"

  def flight_date
    Time.new(date_year, date_month, date_day)
  end

  # uses the year / month / day, along with an "hhmm" string, to
  def inttime_from_hhmm(val, fencepost=nil)
    hour, minutes = [val.to_i / 100, val.to_i % 100]
    res = Time.utc(date_year, date_month, date_day, hour, minutes)
    # if before fencepost, we wrapped around in time
    res += (24 * 60 * 60) if fencepost && (res.to_i < fencepost)
    # p [res, hour, minutes, res.hour, res.min]
    res.to_i
  end

  def act_dep_itime ; @act_dep_itime = inttime_from_hhmm(act_dep_tod)                if act_dep_tod ; end
  def crs_dep_itime ; @crs_dep_itime = inttime_from_hhmm(crs_dep_tod)                               ; end
  def act_arr_itime ; @act_arr_itime = inttime_from_hhmm(act_arr_tod, act_dep_itime) if act_arr_tod ; end
  def crs_arr_itime ; @crs_arr_itime = inttime_from_hhmm(crs_arr_tod, crs_dep_itime)                ; end

  def receive_tail_num(val) ; val = nil if val.to_s == "0" ; super(val) ; end
  def arr_delay(val) val = nil if val.to_s == 0 ; super(val) ; end

  def receive_cancellation_code(val) ; if val == "" then super("Z") else super(val) ; end ; end

  def to_airline_flight
    attrs = self.attributes.reject{|attr,val| [:year, :month, :day, :distance_mi].include?(attr) }
    attrs[:flight_datestr] = flight_date.strftime("%Y%m%d")
    attrs[:distance_km]    = (distance_mi * 1.609_344).to_i

    attrs[:act_dep_tod] = "%04d" % act_dep_tod.to_i if act_dep_tod
    attrs[:crs_dep_tod] = "%04d" % crs_dep_tod.to_i if crs_dep_tod
    attrs[:act_arr_tod] = "%04d" % act_arr_tod.to_i if act_arr_tod
    attrs[:crs_arr_tod] = "%04d" % crs_arr_tod.to_i if crs_arr_tod

    attrs[:act_dep_itime] = act_dep_itime
    attrs[:crs_dep_itime] = crs_dep_itime
    attrs[:act_arr_itime] = act_arr_itime
    attrs[:crs_arr_itime] = crs_arr_itime

    AirlineFlight.receive(attrs)
  end
end


class AirlineFlight
  include Gorillib::Model

  # Identifier
  field :flight_datestr,      String,      position:  0, doc: "Date, YYYYMMDD. Use flight_date method if you want a date"
  field :unique_carrier,      String,      position:  1, doc: "Unique Carrier Code. When the same code has been used by multiple carriers, a numeric suffix is used for earlier users, for example, PA, PA(1), PA(2).",           validates: { length: { in: 0..5 } }
  field :flight_num,          Integer,     position:  2, doc: "flight number"
  # Flight
  field :from_airport,        String,      position:  3, doc: "Origin IATA airport code",      validates: { length: { in: 0..3 } }
  field :into_airport,        String,      position:  4, doc: "Destination IATA airport code", validates: { length: { in: 0..3 } }
  field :tail_num,            String,      position:  5, doc: "Plane tail number",             validates: { length: { in: 0..8 } }
  field :distance_km,         Integer,     position:  6, doc: "Flight distance, in kilometers"
  field :day_of_week,         Integer,     position:  7, doc: "Day of week -- 1 (Monday) - 7 (Sunday)"
  # Departure and Arrival Absolute Time
  field :crs_dep_itime,       IntTime,     position:  8, doc: "scheduled departure time (utc epoch seconds)"
  field :crs_arr_itime,       IntTime,     position:  9, doc: "scheduled arrival time (utc epoch seconds)"
  field :act_dep_itime,       IntTime,     position: 10, doc: "actual departure time (utc epoch seconds)"
  field :act_arr_itime,       IntTime,     position: 11, doc: "actual arrival time (utc epoch seconds)"
  # Departure and Arrival Local Time of Day
  field :crs_dep_tod,         String,     position:  12, doc: "time of day for scheduled departure (local, hhmm)"
  field :crs_arr_tod,         String,     position:  13, doc: "time of day for scheduled arrival (local, hhmm). Not adjusted for wrap-around."
  field :act_dep_tod,         String,     position:  14, doc: "time of day for actual departure (local, hhmm)"
  field :act_arr_tod,         String,     position:  15, doc: "time of day for actual arrival (local, hhmm). Not adjusted for wrap-around."
  # Duration
  field :crs_duration,        Integer,     position: 16, doc: "CRS flight time, in minutes"
  field :act_duration,        Integer,     position: 17, doc: "Actual flight time, in minutes"
  field :air_duration,        Integer,     position: 18, doc: "Air time, in minutes"
  field :taxi_in_duration,    Integer,     position: 19, doc: "taxi in time, in minutes"
  field :taxi_out_duration,   Integer,     position: 20, doc: "taxi out time in minutes"
  # Delay
  field :is_diverted,         :boolean_10, position: 21, doc: "Was the plane diverted? The actual_duration column remains NULL for all diverted flights."
  field :is_cancelled,        :boolean_10, position: 22, doc: "was the flight cancelled?"
  field :cancellation_code,   String,      position: 23, doc: "Reason for cancellation (A = carrier, B = weather, C = NAS, D = security, Z = no cancellation)"
  field :dep_delay,           Integer,     position: 24, doc: "Difference in minutes between scheduled and actual departure time. Early departures show negative numbers. "
  field :arr_delay,           Integer,     position: 25, doc: "Difference in minutes between scheduled and actual arrival time. Early arrivals show negative numbers."
  field :carrier_delay,       Integer,     position: 26, doc: "Carrier delay, in minutes"
  field :weather_delay,       Integer,     position: 27, doc: "Weather delay, in minutes"
  field :nas_delay,           Integer,     position: 28, doc: "National Air System delay, in minutes"
  field :security_delay,      Integer,     position: 29, doc: "Security delay, in minutes"
  field :late_aircraft_delay, Integer,     position: 30, doc: "Late Aircraft delay, in minutes"

  def to_tsv
    attrs = attributes
    attrs[:is_cancelled] = is_cancelled ? 1 : 0
    attrs[:is_diverted]  = is_diverted  ? 1 : 0
    attrs[:act_dep_itime] ||= '         '
    attrs[:act_arr_itime] ||= '         '

    # FIXME
    attrs[:act_duration]  = ((crs_arr_itime - crs_dep_itime) / 60.0).to_i
    attrs[:air_duration]  = attrs[:act_duration] - attrs[:crs_duration]
    attrs.each{|key, val| attrs[key] = val.to_s[-7..-1] if val.to_s.length > 7 } # FIXME: for testing

    attrs.values.join("\t")
  end

  def flight_date
    @flight_date ||= Gorillib::Factory::DateFactory.receive(flight_datestr)
  end

  # checks that the record is sane
  def lint
    {
      act_duration:       (!act_arr_itime) || (act_arr_itime - act_dep_itime == act_duration * 60),
      crs_duration:       (!crs_arr_itime) || (crs_arr_itime - crs_dep_itime == crs_duration * 60),
      cancelled_has_code: (is_cancelled == (cancellation_code != "Z")),
      cancellation_code:  (%w[A B C D Z].include?(cancellation_code)),
      act_duration:       (!act_duration) || (act_duration == (air_duration + taxi_in_duration + taxi_out_duration)),
      dep_delay:          (!act_dep_itime) || (dep_delay == (act_dep_itime - crs_dep_itime)/60.0),
      arr_delay:          (!act_arr_itime) || (arr_delay == (act_arr_itime - crs_arr_itime)/60.0),
    }
  end
end

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
class RawOpenflightAirport
  include Gorillib::Model

  field :airport_ofid, String, doc: "Unique OpenFlights identifier for this airport."
  field :name,       String, doc: "Name of airport. May or may not contain the City name."
  field :city,       String, doc: "Main city served by airport. May be spelled differently from Name."
  field :country,    String, doc: "Country or territory where airport is located."
  field :iata,       String, doc: "3-letter FAA code, for airports located in the USA. For all other airports, 3-letter IATA code, or blank if not assigned."
  field :icao,       String, doc: "4-letter ICAO code; Blank if not assigned."
  field :latitude,   Float,  doc: "Decimal degrees, usually to six significant digits. Negative is South, positive is North."
  field :longitude,  Float,  doc: "Decimal degrees, usually to six significant digits. Negative is West,  positive is East."
  field :altitude,   String, doc: "In feet."
  field :utc_offset, Float,  doc: "Hours offset from UTC. Fractional hours are expressed as decimals, eg. India is 5.5."
  field :dst_rule,   String, doc: "Daylight savings time rule. One of E (Europe), A (US/Canada), S (South America), O (Australia), Z (New Zealand), N (None) or U (Unknown). See the readme for more."

  def to_tsv
    attrs = attributes
    # FIXME
    # attrs.each{|key, val| attrs[key] = val.to_s[0..6] if val.to_s.length > 7 } # FIXME: for testing
    attrs.values.join("\t")
  end

  def to_airport
    attrs = self.compact_attributes
    Airport.receive(attrs)
  end

end

class Airport
  include Gorillib::Model

  field :airport_ofid, String, doc: "Unique OpenFlights identifier for this airport."
  field :iata,         String, doc: "3-letter FAA code, for airports located in the USA. For all other airports, 3-letter IATA code, or blank if not assigned."
  field :icao,         String, doc: "4-letter ICAO code; Blank if not assigned."
  field :utc_offset,   Float,  doc: "Hours offset from UTC. Fractional hours are expressed as decimals, eg. India is 5.5."
  field :dst_rule,     String, doc: "Daylight savings time rule. One of E (Europe), A (US/Canada), S (South America), O (Australia), Z (New Zealand), N (None) or U (Unknown). See the readme for more."
  field :latitude,     Float,  doc: "Decimal degrees, usually to six significant digits. Negative is South, positive is North."
  field :longitude,    Float,  doc: "Decimal degrees, usually to six significant digits. Negative is West,  positive is East."
  field :altitude,     String, doc: "In feet."
  field :country,      String, doc: "Country or territory where airport is located."
  field :city,         String, doc: "Main city served by airport. May be spelled differently from Name."
  field :name,         String, doc: "Name of airport. May or may not contain the City name."

  def utc_time_for(tm)
    utc_time  = tm.get_utc + utc_offset
    utc_time += (60*60) if TimezoneFixup.dst?(tm)
    utc_time
  end

  AIRPORTS = Hash.new unless defined?(AIRPORTS)
  def self.load(raw_file)
    raw_file.each do |line|
      tuple   = line.chomp.strip.split(",")
      raise "yark, spurious fields" unless tuple.length == 11
      tuple.map!{|val| val.gsub(/"/,'') }
      airport = RawOpenflightAirport.from_tuple(*tuple).to_airport
      AIRPORTS[airport.iata] = airport
    end
    nil
  end
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
