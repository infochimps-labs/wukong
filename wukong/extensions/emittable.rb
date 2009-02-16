
Object.class_eval do
  def to_flat() to_s end
end

module Enumerable
  alias_method :to_flat, :to_a
end

Struct.class_eval do
  #
  # The last portion of the class in underscored form
  #
  def resource_name
    @resource_name ||= self.class.to_s.underscore.gsub(%r{.*/([^/]+)\z}, '\1')
  end

  #
  # Flatten for packing as resource name followed by all fields
  #
  def to_flat
    [resource_name] + self.to_a
  end
end

Hash.class_eval do
  def to_flat
    map do |k, v|
      [k.to_flat, v.to_flat].join(":")
    end
  end
end
