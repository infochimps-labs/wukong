module Flat
  module Language
    
    #language definition
    SIMPLE_TYPES = %w{i f s b _}
    SIMPLE_TYPE_RE = "[#{SIMPLE_TYPES.join}]"

    MODIFIERS = %w{+ *}
    MODIFIER_RE = "[#{MODIFIERS.join}]"

    SIMPLE_TOKEN_RE = "#{SIMPLE_TYPE_RE}(?:#{MODIFIER_RE}|[0-9]+)?"

    DATE_TYPES = %w{a A b B c d H I j m M p S U w W x X Y Z}
    DATE_TYPES_RE = "[#{DATE_TYPES.join} ]" # the extra space is supposed to be there
    DATE_TOKEN_RE = "%#{DATE_TYPES_RE}*%" 

    FIXED_POINT_TYPE = 'D'
    FIXED_POINT_SEP = 'e'
    FIXED_POINT_TOKEN_RE = "#{FIXED_POINT_TYPE}\\d+(?:#{FIXED_POINT_SEP}\\d+)?"

    TOKENS = [SIMPLE_TOKEN_RE, DATE_TOKEN_RE, FIXED_POINT_TOKEN_RE]
    TOKEN_RE =  "#{TOKENS.join('|')}"
    CAPTURE_TOKEN_RE =  /(#{TOKENS.join('|')})/

    LANGUAGE_RE = /^(?:(#{TOKEN_RE}) *)+$/

    #total regexes, i.e. regexes that must match the whole string
    TOTAL_SIMPLE_TYPE_RE = /^#{SIMPLE_TOKEN_RE}$/
    TOTAL_FIXED_POINT_RE = /^#{FIXED_POINT_TOKEN_RE}$/
    TOTAL_DATE_RE = /^#{DATE_TOKEN_RE}$/

    #named regexes used for parsing tokens
    NAMED_SIMPLE_TYPE_RE = /(?<type>#{SIMPLE_TYPE_RE})(?:(?<length>[0-9]+)|(?<modifier>#{MODIFIER_RE}))?/
    NAMED_FIXED_POINT_RE = /#{FIXED_POINT_TYPE}(?<length>\d+)(?:#{FIXED_POINT_SEP}(?<power>\d+))?/
    NAMED_DATE_RE = /%(?<format>#{DATE_TYPES_RE})%/

    # Returns true if the supplied string is in
    # Flat's formatting language, as determined
    # by the LANGUAGE_RE regex.
    def self.string_in_lang(str)
      return (not (str =~ LANGUAGE_RE).nil?)
    end
  end
end
