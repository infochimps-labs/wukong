#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require_relative './common'

class RawUfoSighting
  def receive_sighted_at(val)
    return if val == '0000'
    super
  end

  def receive_location_str(val)
    super(sanitize_str(val))
  end
  def receive_duration_str(val)
    super(sanitize_str(val))
  end
  def receive_description(val)
    super(sanitize_str(val))
  end
  def receive_shape(val)
    val = val.strip if val.respond_to?(:strip)
    super(val)
  end

  @@html_encoder ||= HTMLEntities.new

  BAD_CHAR = %r{([^[:graph:]\ ]+)}
  def sanitize_str(val)
    return val unless val.is_a?(String)
    str = @@html_encoder.decode(val.strip)
    str.gsub!(/[\t\u00a0]+/, " ")
    if (str =~ BAD_CHAR) then
      warn Wu::Munging::Utils.safe_json_encode([$1])
      str.gsub!(BAD_CHAR, " ")
    end
    str
  end

  NUM_RANGE_RE   = '(\d*\.?\d*)\s*(?:-|to|or)\s*(\d+\.?\d*)'
  NUM_WORD_RE    = 'one|two|three|four|five|six|seven|eight|nine|ten|few|a\s+few|several|an?'
  APPROX_STR     = 'appr?ox|approximate(?:ly)?|app|aprox|apx|appx'
  DURATION_QUAL  = '~|about|abt|almost|around|under|less\s+than|roughly|&lt;|&gt;|<|>|at\s*least|at\s*most|max|min'
  OTHER_DURATION = 'non-?stop|not\s+known|hovering|unknown|\bunk\b|short|on\s*going'
  DURATION_UNITS = 's|secs?|seconds?|m|mins?|minutes?|hrs?|hours?|days?|nights?|weeks?'
  DURATION_RE    = %r{\A\s*
    (?:         (?<qual>#{APPROX_STR}|#{DURATION_QUAL})[\.\:]?\s*)?
    (?:
      (?:
                (?<num>  #{NUM_RANGE_RE}|\d+|\d+\.\d+|\d+/\d+|#{NUM_WORD_RE}|\d+\s*&amp;\s*\d+)
            \s* (?<unit> #{DURATION_UNITS})
      )|(?:
              (?<other> #{OTHER_DURATION})
      )
    )
    [\.\?\s]*
    (or\sso|\+|plus|approx|\(approx\.?\)|approximately|at\s+least|at\s+most|max|min|maybe)?
    \s*
  \z}ix

  def duration
    return @duration unless @duration.nil?
    return if duration_str.blank?
    if (mm = DURATION_RE.match(duration_str))
      hsh = mm.captures_hash
      hsh.each{|s| s.strip! if s.respond_to?(:strip!) }
      hsh[:qual] ||= hsh[:other]
      unit = case hsh[:unit]
             when /^(?:weeks?)$/i           then :week
             when /^(?:days?|nights?)$/i    then :day
             when /^(?:hrs?|hours?)$/i      then :hr
             when /^(?:m|mins?|minutes?)$/i then :min
             when /^(?:s|secs?|seconds?)$/i then :sec
               when nil then nil
             else warn "Odd unit: #{hsh[:unit]}" ; nil
             end
      num  = case hsh[:num]
             when /#{NUM_RANGE_RE}/i then "#{$1}-#{$2}"
             else                         hsh[:num]
             end
      qual = case duration_str
             when /(#{APPROX_STR})/i then 'approx'
             when /at\s*least/       then 'at least'
             when /at\s*most/        then 'at most'
             when /\babt\b/          then 'about'
             else                         hsh[:qual].try(:downcase)
             end
      @duration = "#{num} #{unit}"
      @duration << " (#{qual})" if qual.present?
    else
      # warn "Bad duration: #{duration_str}"
      @duration = false
    end
    @duration
  end

  def location
    @location ||= LOCATIONS_MAPPING[location_str]
  end

  def to_wire(*args)
    super.tap do |wired|
      wired[:location]    = location.except(:name) if location
      wired[:coordinates] = [location[:longitude], location[:latitude]] if location
      wired[:duration]    = duration if duration
      wired.delete(:_type)
    end.compact_blank
  end

  def to_tsv(*options)
    arr = attributes.map do |key, attr|
      attr.respond_to?(:to_wire) ? attr.to_wire(*options) : attr
    end
    loc_hsh = self.location || {}
    arr.concat([
        loc_hsh[:latitude], loc_hsh[:longitude], loc_hsh[:city], loc_hsh[:county], loc_hsh[:state], loc_hsh[:country],
        (duration || ''),
      ])
    arr.join("\t")
  end

end

if ($0 == __FILE__)
  require('/tmp/locations')
  RawUfoSighting.load_tsv([:ufo_rawd, 'ufo_sightings-raw.tsv']) do |sighting|
    # puts sighting.location_str if (not sighting.location) && (sighting.location_str =~ /^[a-l]/i)
    puts sighting.to_json
    # puts sighting.to_tsv
  end
end
