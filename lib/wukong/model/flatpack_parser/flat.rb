class String
  def match_all regex
    self.to_enum(:scan, regex).map {Regexp.last_match}
  end
end 

module Wukong
  module FlatPack

    # Creates a 'simple' token from the supplied string
    # and position.
    def self.simple_token_from_string(str, position)
      token_pieces = str.match(Language::NAMED_SIMPLE_TYPE_RE)
      t = Flat::Tokens.token_for_indicator(token_pieces[:type])
      t.position = position
      t.length = token_pieces[:length].nil? ? nil : token_pieces[:length].to_i
      t.modifier = token_pieces[:modifier]
      return t
    end

    # Creates a fixed point token. Strict input formatting is
    # enforced if the strict param is true.
    def self.fixed_point_token_from_string(str, position, strict=true)
      float_pieces = str.match(Language::NAMED_FIXED_POINT_RE)
      t = Flat::Tokens::FixedPointToken.new
      t.position = position
      t.strict = strict
      t.power = float_pieces[:power].nil? ? nil : float_pieces[:power].to_i
      t.length = float_pieces[:length].to_i
      return t
    end

    # Validates the supplied format string
    # and creates a parser from it.
    def self.create_parser(str, delimiter_width=0, strict_fixed_point=true)
      return nil unless Language.string_in_lang str
      lang = []
      str.match_all(Language::CAPTURE_TOKEN_RE).each do |match|
        token_str = match[0]
        case token_str
        when Language::TOTAL_SIMPLE_TYPE_RE
          lang << simple_token_from_string(token_str, match.begin(0))
        when Language::TOTAL_FIXED_POINT_RE
          lang << fixed_point_token_from_string(token_str, match.begin(0), strict_fixed_point)
        when Language::TOTAL_DATE_RE
          date_match = token_str.match(Language::NAMED_DATE_RE)
          #TODO: Implement
        end
        if delimiter_width != 0
          t = Flat::Tokens::IgnoreToken.new
          t.position = -1
          t.length = delimiter_width
          lang << t
        end
      end
      lang = lang[0..-2] if delimiter_width != 0 #pop off the delimiter on the end
      return Flat::Parser.new(lang)
    end
  end
end
