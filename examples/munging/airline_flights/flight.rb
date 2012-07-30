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
