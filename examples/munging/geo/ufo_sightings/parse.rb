#!/usr/bin/env ruby
require_relative './common'

class RawUfoSighting
  def receive_sighted_at(val)
    return if val == '0000'
    super
  end

  def receive_location_str(val)
    if val.is_a?(String)
      val = @@html_encoder.decode(val.strip)
    end
    super(val)
  end

  @@html_encoder ||= HTMLEntities.new

  NUM_RANGE_RE   = '\d*\.?\d*\s*(?:-|to|or)\s*\d+\.?\d*'
  NUM_WORD_RE    = 'one|two|three|four|five|six|seven|eight|nine|ten|few|a\s+few|several|an?'
  DURATION_QUAL  = '~|about|abt|almost|around|appr?ox|approximate(?:ly)?|app|aprox|apx|appx|under|less\s+than|roughly|&lt;|&gt;|at\s+least|at\s+most|max|min'
  OTHER_DURATION = 'non-?stop|not\s+known|hovering|unknown|short|on\s*going'
  DURATION_UNITS = 'm|mins?|minutes?|s|secs?|seconds?|hrs?|hours?|days?|weeks?|nights?'
  DURATION_RE    = %r{\A\s*
    (?:         (?<qual>#{DURATION_QUAL})[\.\:]?\s*)?
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
    return if raw_duration.blank?
    if (mm = DURATION_RE.match(raw_duration))
      @duration = mm.captures_hash
    else
      warn "Bad duration: #{raw_duration}"
      @duration = false
    end
  end

  def to_wire(*args)
    super.tap do |wired|
      wired[:duration] = duration if duration
    end
  end
end

if ($0 == __FILE__)
  RawUfoSighting.load_tsv([:ufo_rawd, 'ufo_sightings-raw.tsv']) do |sighting|
    puts sighting.to_tsv
  end
end
