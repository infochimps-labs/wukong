require_relative("accumulator")

module Wukong
  class Processor

    # A processor which counts the total number of its input records.
    #
    # On it's own, this widget is really just a poor man's `wc -l`.
    # It's really intended to serve as a superclass for more complex
    # accumulators.
    #
    # @example Count the total number of input records on the command-line.
    #
    #   $ wc -l input
    #   283 input
    #   $ cat input | wu-local count
    #   283
    class Count < Accumulator

      # The total size of the input recors.
      attr_accessor :size

      # Initializes the count to 0.
      def setup
        super()
        @size = 0
      end

      # Accumulate a `record` by incrmenting the total size.
      #
      # @param [Object] record
      def accumulate record
        self.size += 1
      end

      # Keeps all records in the same group so that one count is
      # emitted at the end.
      #
      # Overriding this method and returning different keys for
      # different records is the beginning of constructing a "group
      # by" type widget.
      #
      # @param [Object] record
      # @return [:__first__group__]
      # @see Group
      def get_key record
        :__first_group__
      end

      # Yields the total size.
      #
      # @yield [size]
      # @yieldparam [Integer] size
      def finalize
        yield self.size
      end

      register
    end
  end
end
