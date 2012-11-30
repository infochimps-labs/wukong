module Wukong

  # :nodoc:
  # 
  # This code is gross and nasty.
  module DynamicGet

    # :nodoc:
    def self.included klass
      klass.send(:field, :separator, String,   :default => "\t")
    end

    # :nodoc:
    def get field, obj
      return obj unless field
      case
      when field.to_s.to_i > 0 && obj.is_a?(String)
        obj.split(separator)[field.to_s.to_i - 1]
      when field.to_s.to_i > 0
        obj[field.to_s.to_i - 1]
      when field.to_s.to_i == 0 && obj.is_a?(String) && obj =~ /^\s*\{/
        begin
          get_nested(field, MultiJson.load(obj))
        rescue MultiJson::DecodeError => e
        end
      when field.to_s.to_i == 0 && (!field.to_s.include?('.')) && obj.respond_to?(field.to_s)
        obj.send(field.to_s)
      when field.to_s.to_i == 0 && obj.respond_to?(:[])
        get_nested(field, obj)
      else obj
      end
    end

    # :nodoc:
    def get_nested fields, obj
      parts = fields.to_s.split('.')
      field = parts.shift
      return unless field
      if slice = obj[field]
        return slice if parts.empty?
        get_nested(parts.join('.'), slice)
      end
    end

  end
end
