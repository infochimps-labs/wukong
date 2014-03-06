module Wukong
  class Processor

    # A base widget for building more complex improver widgets.
    class Improver < Processor

      # The current group of records.
      attr_accessor :group

      # Sets up this improver by defining an initial key (with a
      # value that is unlikely to be found in real data) and calling
      # `#zero` with no record.
      def setup
        @key = :__first_group__
        zero
      end

      def recordize record
        record.split("\t")
      end
      
      #
      # All kinds of assumptions here,
      # record is tab-delimited and the
      # first field is a name of a function
      # to call
      #
      def get_function record
        record.first
      end
      
      # Processes the `record`.
      def process(record)
        fields = recordize(record)
        func   = get_function(fields)
        case func
        when 'zero' then
          yield zero
        when 'accumulate' then
          accumulate(fields[1..-1])
        when 'improve' then
          yield improve(fields[1], self.group)
          self.group = []
        else
          raise NoMethodError, "undefined method #{func} for Improver"
        end
        STDOUT.flush # WHY? Because.
      end

      # Starts accumulation for a new key. Return what you would
      # with no improvements.
      def zero
        self.group = []
      end

      # Accumulates another +record+.
      #
      # @param [Object] record
      def accumulate record
        self.group << record
      end

      # Improve prev with group
      #
      #
      def improve prev, group
      end
      
    end
  end
end
