require 'htmlentities'
require 'addressable/uri'

module Wukong
  #
  # By default (or explicitly with the :xml strategy), convert string to
  # * XML-encoded ASCII,
  #
  # * with a guarantee that the characters " quote, ' apos \\ backslash,
  #   carriage-return \r newline \n and tab \t (as well as all other control
  #   characters) are encoded.
  #
  # * Any XML-encoding in the original text is encoded with no introspection:
  #     encode_str("&lt;a href=\"foo\"&gt;")
  #     # => "&amp;lt;a href=&quot;foo&quot;&amp;gt;"
  #
  # * Useful: http://rishida.net/scripts/uniview/conversion.php
  #
  # With the :url strategy,
  # * URL-encode the string
  # * This is as strict as possible: encodes all but alphanumeric and _ underscore.
  #   The resulting string is thus XML- and URL-safe.
  #   http://addressable.rubyforge.org/api/classes/Addressable/URI.html#M000010
  #
  # Wukong.decode_str(Wukong.encode_str(str)) returns the original str
  #
  #
  #
  def self.encode_str str, strategy=:xml
    begin
      case strategy
      when :xml        then self.html_encoder.encode(str, :basic, :named, :decimal).gsub(/\\/, '&#x5C;')
      when :url        then Addressable::URI.encode_component(str, /[^\w]/)
      else raise "Don't know how to encode with strategy #{strategy}"
      end
    rescue ArgumentError => e
      str.gsub!(/[^\w\s\.\-@#%]+/, '')
      '!!bad_encoding!! ' + str
    end
  end
  # HTMLEntities encoder instance
  def self.html_encoder
    @html_encoder ||= HTMLEntities.new
  end

  #
  # Decode string from its encode_str representation.  This can include
  # dangerous things such as tabs, newlines, backslashes and cryptofascist
  # propaganda.
  #
  def self.decode_str str, strategy=:xml
    case strategy
    when :xml        then HTMLEntities.decode_entities(str)
    when :url        then Addressable::URI.unencode_component(str)
    else raise "Don't know how to decode with strategy #{strategy}"
    end
  end

  #
  # Replace each given field in the hash with its
  # encoded value
  #
  def self.encode_components hsh, *fields
    fields.each do |field|
      hsh[field] = hsh[field].to_s.wukong_encode if hsh[field]
    end
  end
end

String.class_eval do

  #
  # Strip control characters that might harsh our buzz, TSV-wise
  # See Wukong.encode_str
  #
  def wukong_encode! *args
    replace self.wukong_encode(*args)
  end

  def wukong_encode(*args)
    Wukong.encode_str(self, *args)
  end

  #
  # Decode string into original (and possibly unsafe) form
  # See Wukong.encode_str and Wukong.decode_str
  #
  def wukong_decode!(*args)
    replace self.wukong_decode(*args)
  end

  def wukong_decode
    Wukong.decode_str(self, *args)
  end

  #
  # Takes an XML-encoded or plaintext string and forces it into canonical encoding
  #
  def wukong_recode!(*args)
    replace self.wukong_decode(*args).wukong_encode(*args)
  end
  def wukong_recode
    Wukong.encode_str(Wukong.decode_str(self, *args), *args)
  end
end

Struct.class_eval do
  def recode!(*args)
    each_pair{|k,v| v.wukong_recode!(*args) if (v && v.respond_to?(:wukong_recode!)) }
  end
end
