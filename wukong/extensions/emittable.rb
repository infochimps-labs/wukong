
Object.class_eval do
  def to_flat() [to_s] end
end

module Enumerable
  alias_method :to_flat, :to_a
end

Struct.class_eval do
  #
  # The last portion of the class in underscored form
  # note memoization
  #
  def resource_name
    @resource_name ||= self.class.to_s.underscore.gsub(%r{.*/([^/]+)\z}, '\1')
  end

  #
  # Flatten for packing as resource name followed by all fields
  #
  def to_flat include_key=true
    if include_key.is_a? Proc
      sort_key = include_key.call(self)
    elsif include_key && respond_to?(:key)
      sort_key = [resource_name, key].flatten.join("-")
    else
      sort_key = resource_name
    end
    [sort_key, *to_a]
  end
end

Hash.class_eval do
  def to_flat
    map do |k, v|
      [k.to_flat, v.to_flat].join(":")
    end
  end
end

DateTime.class_eval do
  def to_flat
    strftime("%Y%m%d%H%M%S")
  end

  def self.parse_and_flatten str
    DateTime.parse(str, true).to_flat
  end
end
