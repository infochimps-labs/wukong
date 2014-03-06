module Wukong
  #
  # A hashlike has to
  #
  # *
  # * The arguments to your initializer should be the same as the keys, in order
  #   If not, you must override #from_hash
  #
  #
  module HashLike

    # List of possible keys --
    # delegates to the class
    def keys
      self.class.keys
    end

    #
    # Return a Hash containing only values for the given keys.
    #
    # Since this is intended to mirror Hash#slice it will harmlessly ignore keys
    # not present in the struct.  They will be unset (hsh.include? is not true)
    # as opposed to nil.
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
    # Analagous to Hash#each_pair
    #
    def pairs
      self.class.members.map{|attr| [attr, self[attr]] }
    end

    #
    # Analagous to Hash#each_pair
    #
    def each_pair *args, &block
      pairs.each(*args, &block)
    end

    #
    # Analagous to Hash#merge
    #
    def merge *args
      self.dup.merge!(*args)
    end
    def merge! hsh, &block
      raise "can't handle block arg yet" if block
      hsh.each_pair{|key, val| self.send("#{key}=", val) if self.respond_to?("#{key}=") }
      self
    end
    alias_method :update, :merge!

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
    def deep_merge hsh2
      merge hsh2, &Hash::DEEP_MERGER
    end

    #
    # remove all key-value pairs where the value is blank
    #
    def compact_blank
      to_hash.compact_blank!
    end

    module ClassMethods
      #
      # Instantiate an instance of the struct from a hash
      #
      # Specify has_symbol_keys if the supplied hash's keys are symbolic;
      # otherwise they must be uniformly strings
      #
      def from_hash(hsh, has_symbol_keys=false)
        extract_keys = has_symbol_keys ? self.keys.map(&:to_sym) : self.keys.map(&:to_s)
        self.new(*hsh.values_of(*extract_keys))
      end
      #
      # The last portion of the class in underscored form
      # memoized
      #
      def resource_name
        @resource_name ||= self.class_basename.underscore.to_sym
      end
      # The last portion of the class name
      # memoized
      #
      # @example
      #   This::That::TheOther.new.class_basename   # => TheOther
      def class_basename
        @class_basename ||= self.to_s.gsub(%r{.*::}, '')
      end
    end

    def self.included base
      base.class_eval do
        extend ClassMethods
      end
    end

    def coerce_attr attr, coerce_blank_to_nil=false, &block
      orig_val = self.send(attr)
      new_val = (coerce_blank_to_nil && orig_val.blank?) ? nil : block.call(orig_val)
      self.send("#{attr}=", new_val)
    end

    def coerce_to_int! attr, *args
      coerce_attr(attr, *args) do |val|
        val.to_i
      end
    end

    def coerce_to_date! attr, *args
      coerce_attr(attr, *args){|val| val.is_a?(DateTime) ? val : DateTime.parse(val) rescue nil }
    end

  end

end
