require 'gorillib'
require 'gorillib/model'
require 'gorillib/model/serialization'

class RawWeatherReport
  include Gorillib::Model

  field :usaf_station_id, Integer
  field :wban_station_id, Integer
  field :call_letters, String

  field :report_type, String
  field :quality_control_process, String
  field :data_source, String 

  field :obs_date, String
  field :obs_time, String
  
  field :wstn_latitude, Float
  field :wstn_longitude, Float
  field :wstn_elevation, Integer
 
  field :wind_direction, Integer
  field :wind_direction_qual, String
  field :wind_observation_type, String
  field :wind_speed, Float
  field :wind_speed_qual, String
  
  field :ceiling_height, Integer
  field :ceiling_qual, String
  field :ceiling_determination, String
  field :cavok, :boolean

  field :visibility, Integer
  field :visibility_qual, String
  field :visibility_variability, :boolean
  field :visibility_variability_qual, String

  field :air_temp, Float
  field :air_temp_qual, String

  field :dew_point, Float
  field :dew_point_qual, String

  field :sea_level_pressure, Float
  field :sea_level_pressure_qual, String

  field :raw_extended_observations, String

  # This assumes that r is a list of values in the order that
  # they are described in http://www1.ncdc.noaa.gov/pub/data/noaa/ish-format-document.pdf
  # with 2 differences:
  #   - the first field in the format document
  #     which represents the number of characters of additional
  #     data after the end of the mandatory data section is
  #     not present
  #   - all information after the 'mandatory data' section is
  #     globbed into a string at the end of the list
  # 
  # This method also makes assumptions about the types of 
  # values in 'r'. Ensure that they match the types defined
  # above. For maximum ease of use, use the flat-file parser
  # provided to parse the NOAA records.
  def receive_record r
    self.usaf_station_id = r[0]
    self.wban_station_id = r[1]
    self.obs_date = r[2]
    self.obs_time = r[3]
    self.data_source = r[4]
    self.wstn_latitude = r[5]
    self.wstn_longitude = r[6]
    self.report_type = r[7]
    self.wstn_elevation = r[8]
    self.call_letters = r[9]
    self.quality_control_process = r[10]
    self.wind_direction = r[11]
    self.wind_direction_qual = r[12]
    self.wind_observation_type = r[13]
    self.wind_speed = r[14]
    self.wind_speed_qual = r[15]
    self.ceiling_height = r[16]
    self.ceiling_qual = r[17]
    self.ceiling_determination = r[18]
    self.cavok = r[19]
    self.visibility = r[20]
    self.visibility_qual = r[21]
    self.visibility_variability = r[22]
    self.visibility_variability_qual = r[23]
    self.air_temp = r[24]
    self.air_temp_qual = r[25]
    self.dew_point = r[26]
    self.dew_point_qual = r[27]
    self.sea_level_pressure = r[28]
    self.sea_level_pressure_qual = r[29]
    self.raw_extended_observations = r[30]
  end

  def to_weather_report_hash
    hash = to_wire
    new_hash = {}
    hash.each do |key,val|
      case key
      when /^.*_qual$/
        field = /^(.*)_qual$/.match(key)[1].to_sym
        new_hash[field] = {value: new_hash[field], quality: val}
      else
        if new_hash[key].nil?
          new_hash[key] = val
        elsif new_hash[key].is_a(Hash)
          new_hash[key][:value] = val
        end
      end
    end
    w = WeatherReport.new
    w.receive! new_hash
    return w
  end
end

class ReportMetadata
  include Gorillib::Model
  field :wind_direction_qual, String
  field :wind_speed_qual, String
  field :ceiling_qual, String
  field :visibility_qual, String
  field :visibility_variability_qual, String
  field :air_temp_qual, String
  field :dew_point_qual, String
  field :sea_level_pressure_qual, String
 
end
  
class WeatherReport
  include Gorillib::Model

  field :wstn_id, String #wban-usad

  field :wstn_latitude, Float
  field :wstn_longitude, Float
  field :wstn_elevation, Float

  field :obs_date, String
  field :obs_time, Time
 
  field :wind_direction, Integer
  field :wind_observation_type, String
  field :wind_speed, Float
  
  field :ceiling_height, Integer
  field :ceiling_determination, String
  field :cavok, :boolean

  field :visibility, Integer
  field :visibility_variability, :boolean

  field :air_temp, Float

  field :dew_point, Float

  field :sea_level_pressure, Float

  field :metadata, ReportMetadata, default: ReportMetadata.new

  #BLANKISH_INT = [9,99,999,9999,99999]
  #BLANKISH_INT_NEG = [-9,-99,-999,-9999,-99999]
  #TODO: Figure out a proper way to check for blankness 
  # without resorting to lists

  def receive!(hsh={})
    # prune the quality fields
    hsh.keys.each do |key|
      next if (key.to_s =~ /[^_]*_qual/).nil?
      val = hsh.delete(key)
      metadata.send("receive_#{key.to_s}", val)
    end
    # transform the ids
    if hsh.keys.include? :usaf_station_id and hsh.keys.include? :wban_station_id
      id = hsh.delete(:usaf_station_id).to_s
      id += "-#{hsh.delete :wban_station_id}"
      hsh[:wstn_id] = id
    end
    super(hsh)
  end
end
