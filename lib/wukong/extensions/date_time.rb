require 'time'
require 'date'
DateTime.class_eval do
  #
  # Parses the time but never fails.
  # Return value is always in the UTC time zone.
  #
  # A flattened datetime -- a 12-digit YYYYmmddHHMMMSS -- is fixed to the UTC
  # time zone by parsing it as YYYYmmddHHMMMSSZ <- 'Z' at end
  #
  def self.parse_safely dt
    return nil if dt.blank?
    begin
      if dt.to_s =~ /\A\d{12}Z?\z/
        parse(dt+'Z', true)
      else
        parse(dt, true).utc
      end
    rescue StandardError => e
      Log.info e
    end
  end

  def self.parse_and_flatten str
    parse_safely(str).to_flat
  end
end
