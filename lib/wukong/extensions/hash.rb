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
  ::Hash::DEEP_MERGER = proc do |key,v1,v2|
    (v1.respond_to?(:merge) && v2.respond_to?(:merge)) ? v1.merge(v2.compact, &Hash::DEEP_MERGER) : (v2.nil? ? v1 : v2)
  end unless defined?(::Hash::DEEP_MERGER)

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
  end unless method_defined?(:deep_merge)

  def deep_merge! hsh2
    merge! hsh2, &Hash::DEEP_MERGER
  end unless method_defined?(:deep_merge!)

  #
  # Treat hash as tree of hashes:
  #
  #     x = { 1 => :val, :subhash => { 1 => :val1 } }
  #     x.deep_set(:subhash, :cat, :hat)
  #     # => { 1 => :val, :subhash => { 1 => :val1,   :cat => :hat } }
  #     x.deep_set(:subhash, 1, :newval)
  #     # => { 1 => :val, :subhash => { 1 => :newval, :cat => :hat } }
  #
  #
  def deep_set *args
    val      = args.pop
    last_key = args.pop
    # dig down to last subtree (building out if necessary)
    hsh = args.empty? ? self : args.inject(self){|h, k| h[k] ||= {} }
    # set leaf value
    hsh[last_key] = val
  end unless method_defined?(:deep_set)

  #
  # Treat hash as tree of hashes:
  #
  #     x = { 1 => :val, :subhash => { 1 => :val1 } }
  #     x.deep_get(:subhash, 1)
  #     # => :val
  #     x.deep_get(:subhash, 2)
  #     # => nil
  #     x.deep_get(:subhash, 2, 3)
  #     # => nil
  #     x.deep_get(:subhash, 2)
  #     # => nil
  #
  def deep_get *args
    last_key = args.pop
    # dig down to last subtree (building out if necessary)
    hsh = args.inject(self){|h, k| h[k] || {} }
    # get leaf value
    hsh[last_key]
  end unless method_defined?(:deep_get)


  #
  # Treat hash as tree of hashes:
  #
  #     x = { 1 => :val, :subhash => { 1 => :val1, 2 => :val2 } }
  #     x.deep_delete(:subhash, 1)
  #     #=> :val
  #     x
  #     #=> { 1 => :val, :subhash => { 2 => :val2 } }
  #
  def deep_delete *args
    last_key  = args.pop
    last_hsh  = args.empty? ? self : (deep_get(*args)||{})
    last_hsh.delete(last_key)
  end unless method_defined?(:deep_delete)

  #
  # remove all key-value pairs where the value is nil
  #
  def compact
    reject{|key,val| val.nil? }
  end unless method_defined?(:compact)
  #
  # Replace the hash with its compacted self
  #
  def compact!
    replace(compact)
  end unless method_defined?(:compact!)

  #
  # remove all key-value pairs where the value is blank
  #
  def compact_blank
    reject{|key,val| val.blank? }
  end
  #
  # Replace the hash with its compact_blank'ed self
  #
  def compact_blank!
    replace(compact_blank)
  end

  # Stolen from ActiveSupport::CoreExtensions::Hash::ReverseMerge.
  def reverse_merge(other_hash)
    other_hash.merge(self)
  end

  # Stolen from ActiveSupport::CoreExtensions::Hash::ReverseMerge.
  def reverse_merge!(other_hash)
    replace(reverse_merge(other_hash))
  end

end
