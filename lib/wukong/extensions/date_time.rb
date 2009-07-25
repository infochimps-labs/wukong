require 'time'
DateTime.class_eval do
  #
  # Parses the time but never fails.
  #
  # A flattened time -- a 12-digit YYYYmmddHHMMMSS -- is treated as a UTC
  # datetime.
  #
  def self.parse_safely dt
    begin
      if dt.to_s =~ /\A\d{12}Z?\z/
        parse(dt+'Z', true)
      else
        parse(dt, true)
      end
    rescue
      nil
    end
  end

  def self.parse_and_flatten str
    parse_safely(str).to_flat
  end
end
