module Wukong
  module Datatypes
    #
    # Infinity is bigger than any number
    #
    #
    Infinity = 1.0/0


    #
    # A simple enumerated class
    #
    #   class MyEnum < Enum
    #     enumerates :firefox, :safari, :ie, :chrome, :other
    #   end
    #   MyEnum[1].to_s # => "safari"
    #
    #
    class Enum
      attr_accessor            :val
      class_inheritable_accessor :names
      def initialize val
        self.val = val
      end
      # MyEnum[val] is sugar for MyEnum.new(val)
      def self.[] *args
        new *args
      end
      def to_i
        val
      end
      def to_s
        return nil if val.nil?
        self.class.names[val]
      end
      def inspect
        "<#{self.class.to_s} #{to_i} (#{to_s})>"
      end
      # returns the value corresponding to that string representation
      def index *args
        # delegate
        self.class.names.index *args
      end
      def to_flat
        to_s #to_i
      end

      #
      # Use enumerates to set the class' names
      #
      #   class MyEnum < Enum
      #     enumerates :firefox, :safari, :ie, :chrome, :other
      #   end
      #   MyEnum[1].to_s # => "safari"
      #
      #
      def self.enumerates *names
        self.names = names.map(&:to_s)
      end

      def self.to_sql_str
        "ENUM('#{names.join("', '")}')"
      end

      def self.typify
        'chararray'
      end
    end


    #
    # Note that bin 0 is
    #
    class Binned < Enum
      class_inheritable_reader :bins, :empty_bin_name
      @@empty_bin_name = '(none)'

      def bins
        self.class.bins
      end

      # FIXME -- doesn't respect a lower bound.
      def initialize val
        return super(val) if val.nil?
        last_top = bins.first
        bins.each_with_index do |bin_top, idx|
          return super(idx) if val <= bin_top
        end
        return super(bins.length)
      end

      def self.enumerates *bins
        options = bins.extract_options!
        write_inheritable_attribute :bins, bins
        last_top = bins.shift
        # bins.unshift bins.first if last_top == -Infinity
        names = bins.map do |bin_top|
          name = bin_name last_top, bin_top, options
          last_top = (last_top.is_a?(Integer) ? bin_top + 1 : bin_top)
          name
        end
        super(*names)
      end

      #
      # Bins
      #
      def self.bin_name lo_val, hi_val, options = { }
        # case lo_val
        # when Integer then lo_val = [lo_val+1, hi_val].compact.min
        # end
        case
        when lo_val == -Infinity then "< #{hi_val}"
        when hi_val ==  Infinity then "#{lo_val}+"
        when (lo_val == hi_val)  then    lo_val
        else                         "#{lo_val} - #{hi_val}"
        end
      end

    end
  end
end

