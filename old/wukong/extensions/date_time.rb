require 'time'
require 'date'

class Time
  # strftime() format to flatten a date
  FLAT_FORMAT = "%Y%m%d%H%M%S"
  # Flatten
  def to_flat
    utc.strftime(FLAT_FORMAT)
  end

  #
  # Parses the time but never fails.
  # Return value is always in the UTC time zone.
  #
  # A flattened datetime -- a 14-digit YYYYmmddHHMMMSS -- is fixed to the UTC
  # time zone by parsing it as YYYYmmddHHMMMSSZ <- 'Z' at end
  #
  def self.parse_safely dt
    return nil if dt.blank?
    begin
      case
      when dt.is_a?(Time)               then dt.utc
      when (dt.to_s =~ /\A\d{14}\z/)    then parse(dt.to_s+'Z', true)
      else                                   parse(dt.to_s,     true).utc
      end
    rescue StandardError => e
      Log.debug e
    end
  end

  def self.parse_and_flatten str
    parse_safely(str).to_flat
  end
end

class DateTime < Date
  # strftime() format to flatten a date
  FLAT_FORMAT = "%Y%m%d%H%M%S"
  # Flatten
  def to_flat
    strftime(FLAT_FORMAT)
  end
end

class Date
  # strftime() format to flatten a date
  FLAT_FORMAT = "%Y%m%d"
  # Flatten
  def to_flat
    strftime(FLAT_FORMAT)
  end
end
