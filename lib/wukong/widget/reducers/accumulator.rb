module Wukong
  class Processor

    # A base widget for building more complex accumulative widgets.
    class Accumulator < Processor

      # The current key used to define the current group being
      # accumulated.
      attr_accessor :key

      # The current group of records.
      attr_accessor :group

      # Sets up this accumulator by defining an initial key (with a
      # value that is unlikely to be found in real data) and calling
      # `#start` with no record.
      def setup
        @key   = :__first_group__
        start(nil)
      end

      # Processes the `record`.
      #
      # If the record is part of the current group (has a key that is
      # the same as the current key) then will call `accumulate` with
      # the record.
      #
      # If the record has a different key, will call `finalize` and
      # then call `start` with the record.
      #
      # @param [Object] record
      # @yield [finalized_record] each record yielded by `finalize`
      # @yieldparam [Object] finalized_record
      # @see #accumulate
      # @see #finalize
      # @see #get_key
      # @see #start
      def process(record)
        this_key = get_key(record)
        if this_key != self.key
          finalize { |record| yield record }  unless self.key == :__first_group__
          self.key = this_key
          start record
        end
        accumulate(record)
      end

      # Starts accumulation for a new group of records with a new key.
      # This is where you can reset counters, clear caches, &c.
      #
      # @param [Object] record
      def start record
      end

      # Gets the key from the given +record+.  By default a record's
      # key is just the record itself.
      #
      # @param [Object] record
      # @return [Object] the record's key
      def get_key record
        record
      end

      # Accumulates another +record+.
      #
      # Does nothing by default, intended for you to override.
      #
      # @param [Object] record
      def accumulate record
      end
    end
  end
end
