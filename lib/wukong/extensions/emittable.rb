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
  def self.resource_name
    @resource_name ||= self.to_s.gsub(%r{.*::}, '').underscore.to_sym
  end
  #
  # Flatten for packing as resource name followed by all fields
  #
  def to_flat include_key=false
    if include_key.is_a? Proc
      sort_key = include_key.call(self)
    elsif (! include_key.blank?) && respond_to?(:key)
      sort_key = [self.class.resource_name, key].flatten.join("-")
    else
      sort_key = self.class.resource_name
    end
    [sort_key, *to_a] # .map(&:to_flat).flatten
  end
end

module HashLike
  #
  # Flatten for packing as resource name followed by all fields
  #
  def to_flat include_key=true
    if include_key.is_a? Proc
      sort_key = include_key.call(self)
    elsif include_key && respond_to?(:key)
      sort_key = [self.class.resource_name, key].flatten.join("-")
    else
      sort_key = self.class.resource_name
    end
    [sort_key, *to_a] # .map(&:to_flat).flatten
  end
end

Hash.class_eval do
  def to_flat
    map do |k, v|
      [k.to_flat, v.to_flat].join(":")
    end
  end
end

class Integer
  #
  # Express boolean as 1 (true) or 0 (false).  In contravention of typical ruby
  # semantics (but in a way that is more robust for wukong-like batch
  # processing), the number 0, the string '0', nil and false are all considered
  # false. (This also makes the method idempotent: repeated calls give same result.)
  #
  def self.unbooleanize bool
    case bool
    when 0, '0', false, nil then 0
    else                         1
    end
  end
end
