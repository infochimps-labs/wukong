require 'hadoop/extensions/hash'
require 'hadoop/extensions/symbol'

#
# extensions/struct
#
# Add several methods to make a struct duck-type much more like a Hash
#
Struct.class_eval do
  #
  # Return a Hash containing only values for the given keys.
  #
  # Since this is intended to mirror Hash#slice it will harmlessly ignore keys
  # not present in the struct.  They will be unset (hsh.include? is not true)
  # rather than nil.
  #
  def slice *keys
    keys.inject({}) do |hsh, key|
      hsh[key] = send(key) if respond_to?(key)
      hsh
    end
  end
  #
  # values_at like a hash
  #
  # Since this is intended to mirror Hash#values_at it will harmlessly ignore
  # keys not present in the struct
  #
  def values_of *keys
    keys.map{|key| self.send(key) if respond_to?(key) }
  end

  #
  # Convert to a hash
  #
  def to_hash
    slice(*self.class.members)
  end

  #
  # Instantiate an instance of the struct from a hash
  #
  # Specify has_symbol_keys if the supplied hash's keys are symbolic;
  # otherwise they must be uniformly strings
  #
  def self.from_hash(hsh, has_symbol_keys=false)
    keys = self.members
    keys = keys.map(&:to_sym) if has_symbol_keys
    self.new *hsh.values_of(*keys)
  end

  #
  # Analagous to Hash#each_pair
  #
  def each_pair *args, &block
    self.to_hash.each_pair(*args, &block)
  end

  #
  # Analagous to Hash#merge
  #
  def merge *args
    self.dup.merge! *args
  end
  def merge! hsh, &block
    raise "can't handle block arg yet" if block
    hsh.each_pair{|key, val| self[key] = val }
    self
  end
  alias_method :update, :merge!

end


