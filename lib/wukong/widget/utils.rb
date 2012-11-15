module Wukong
  module DynamicGet

    def self.included klass
      klass.send(:field, :separator, String,   :default => "\t")
      klass.send(:field, :on,        Whatever, :default => nil)
    end
    
    def get field, obj
      return obj unless field
      case
      when field.is_a?(Fixnum) || field.to_s.to_i > 0
        # assume delimited
        obj.split(separator)[field]
      when field.to_s.to_i == 0
        # assume complex field so it's a Hash, try JSON
        begin
          get_nested(field, MultiJson.load(obj))
        rescue MultiJson::DecodeError => e
          nil
        end
      end
    end

    def get_nested fields, obj
      parts = fields.to_s.split('.')
      field = parts.shift
      return unless field
      if obj.include?(field)
        slice = obj[field]
        return slice if parts.empty?
        get_nested(parts.join('.'), slice)
      end
    end

  end
end
