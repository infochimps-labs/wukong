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

  # lambda for recursive merges
  Hash::DEEP_MERGER = proc do |key,v1,v2|
    (v1.respond_to?(:merge) && v2.respond_to?(:merge)) ? v1.merge(v2.compact, &Hash::DEEP_MERGER) : (v2.nil? ? v1 : v2)
  end

  #
  # Merge hashes recursively.
  # Nothing special happens to array values
  #
  #     x = { :subhash => { 1 => :val_from_x, 222 => :only_in_x, 333 => :only_in_x }, :scalar => :scalar_from_x}
  #     y = { :subhash => { 1 => :val_from_y, 999 => :only_in_y },                    :scalar => :scalar_from_y }
  #     x.deep_merge y
  #     => {:subhash=>{1=>:val_from_y, 222=>:only_in_x, 333=>:only_in_x, 999=>:only_in_y}, :scalar=>:scalar_from_y}
  #     y.deep_merge x
  #     => {:subhash=>{1=>:val_from_x, 222=>:only_in_x, 333=>:only_in_x, 999=>:only_in_y}, :scalar=>:scalar_from_x}
  #
  # Nil values always lose.
  #
  #     x = {:subhash=>{:nil_in_x=>nil, 1=>:val1,}, :nil_in_x=>nil}
  #     y = {:subhash=>{:nil_in_x=>5},              :nil_in_x=>5}
  #     y.deep_merge x
  #     => {:subhash=>{1=>:val1, :nil_in_x=>5}, :nil_in_x=>5}
  #     x.deep_merge y
  #     => {:subhash=>{1=>:val1, :nil_in_x=>5}, :nil_in_x=>5}
  #
  def deep_merge hsh2
    merge hsh2, &Hash::DEEP_MERGER
  end

  def deep_merge! hsh2
    merge! hsh2, &Hash::DEEP_MERGER
  end


  #
  # Treat hash as tree of hashes:
  #
  #     x = { 1 => :val, :subhash => { 1 => :val1 } }
  #     x.deep_set(:subhash, 3, 4)
  #     # => { 1 => :val, :subhash => { 1 => :val1,   3 => 4 } }
  #     x.deep_set(:subhash, 1, :newval)
  #     # => { 1 => :val, :subhash => { 1 => :newval, 3 => 4 } }
  #
  #
  def deep_set *args
    hsh = self
    head_keys = args[0..-3]
    last_key  = args[-2]
    val       = args[-1]
    # grab last subtree (building out if necessary)
    head_keys.each{|key| hsh = (hsh[key] ||= {}) }
    # set leaf value
    hsh[last_key] = val
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
