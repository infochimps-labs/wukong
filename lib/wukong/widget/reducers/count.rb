require_relative("accumulator")

module Wukong
  class Processor
    class Count < Accumulator

      attr_accessor :size

      def setup
        super()
        @size = 0
      end

      def accumulate record
        self.size += 1
      end

      def get_key record
        :__first_group__
      end

      def finalize
        yield self.size
      end

      register
    end
  end
end
