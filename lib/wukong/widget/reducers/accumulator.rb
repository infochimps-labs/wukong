module Wukong
  class Processor
    class Accumulator < Processor

      attr_accessor :key, :group

      def setup
        @key   = :__first_group__
        start(nil)
      end
      
      def process(record)
        this_key = get_key(record)
        if this_key != self.key
          finalize { |record| yield record }  unless self.key == :__first_group__
          self.key = this_key
          start record
        end
        accumulate(record)
      end

      def start record
      end
      
      def get_key record
        record
      end
      
      def accumulate record
      end
    end
  end
end
