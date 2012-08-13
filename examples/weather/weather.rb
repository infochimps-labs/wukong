require 'gorillib'
require 'gorillib/model'
require 'gorillib/model/serialization'
require 'gorillib/model/positional_fields'

class RawWeatherReport
  include Gorillib::Model
  include Gorillib::Model::PositionalFields

  field :usaf_station_id, Integer

  # wban id appears to have 99999 as a blank value even though 
  # it is not specified as such in the docs
  field :wban_station_id, Integer 
  
  field :obs_date, String
  field :obs_time, String

  field :obs_data_source, String, blankish: ["9", '', nil]

  field :wstn_latitude, Float, blankish: [99.999, '', nil]
  field :wstn_longitude, Float, blankish: [999.999, '' , nil]

  field :report_type_code, String, blankish: ["99999", '', nil]
    
  field :wstn_elevation, Integer, blankish: [9999, '', nil]
  
  field :wstn_call_letters, String, blankish: ["99999", '', nil]
  
  field :quality_control_process_name, String
 
  field :wind_direction, Integer, blankish: [999, '', nil]
  field :wind_direction_qual, String
  field :wind_observation_type, String, blankish: ["9", '', nil]
  field :wind_speed, Float, blankish: [999.9, '', nil]
  field :wind_speed_qual, String
  
  field :ceiling_height, Integer, blankish: [99999, '', nil]
  field :ceiling_qual, String
  field :ceiling_determination, String, blankish:['9', '', nil]
  field :cavok, :boolean

  field :visibility, Integer, blankish: [999999, '', nil]
  field :visibility_qual, String
  field :visibility_variability_code, String, blankish: ['9', '', nil]
  field :visibility_variability_code_qual, String

  field :air_temp, Float, blankish: [999.9, '', nil]
  field :air_temp_qual, String

  field :dew_point, Float, blankish: [999.9, '', nil]
  field :dew_point_qual, String

  field :sea_level_pressure, Float, blankish: [9999.9, '' , nil]
  field :sea_level_pressure_qual, String

  field :raw_extended_observations, String
end

class ReportMetadata
  include Gorillib::Model
  field :wind_direction_qual, String
  field :wind_speed_qual, String
  field :ceiling_qual, String
  field :visibility_qual, String
  field :visibility_variability_code_qual, String
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
  field :obs_time, String
 
  field :wind_direction, Integer
  field :wind_observation_type, String
  field :wind_speed, Float
  
  field :ceiling_height, Integer
  field :ceiling_determination, String
  field :cavok, :boolean

  field :visibility, Integer
  field :visibility_variability_code, :boolean

  field :air_temp, Float

  field :dew_point, Float

  field :sea_level_pressure, Float

  field :metadata, ReportMetadata, default: ReportMetadata.new

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
