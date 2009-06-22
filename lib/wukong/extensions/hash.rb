#
# h2. extensions/hash.rb -- hash extensions
#

require 'set'
class Hash

  # Slice a hash to include only the given keys. This is useful for
  # limiting an options hash to valid keys before passing to a method:
  #
  #   def search(criteria = {})
  #     assert_valid_keys(:mass, :velocity, :time)
  #   end
  #
  #   search(options.slice(:mass, :velocity, :time))
  # Returns a new hash with only the given keys.
  def slice(*keys)
    allowed = Set.new(respond_to?(:convert_key) ? keys.map { |key| convert_key(key) } : keys)
    reject{|key,| !allowed.include?(key) }
  end
  #
  # Replace the hash with only the given keys.
  #
  def slice!(*keys)
    replace(slice(*keys))
  end
  #
  # #values_of is an alias for #values_at, but can be called on a Hash, a
  # Struct, or an instance of a class that includes HashLike
  #
  alias_method :values_of, :values_at

  #
  # Create a hash from an array of keys and corresponding values.
  #
  def self.zip(keys, values, default=nil, &block)
    hash = block_given? ? Hash.new(&block) : Hash.new(default)
    keys.zip(values){|key,val| hash[key]=val }
    hash
  end

  # Stolen from ActiveSupport::CoreExtensions::Hash::ReverseMerge.
  def reverse_merge(other_hash)
    other_hash.merge(self)
  end

  # Stolen from ActiveSupport::CoreExtensions::Hash::ReverseMerge.
  def reverse_merge!(other_hash)
    replace(reverse_merge(other_hash))
  end

  #
  # remove all key-value pairs where the value is nil
  #
  def compact
    reject{|key,val| val.nil? }
  end
  #
  # Replace the hash with its compacted self
  #
  def compact!
    replace(compact)
  end

end
