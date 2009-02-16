module Wukong
  module Streamer
    #
    # Emit each unique key and the count of its occurrences
    #
    class CountKeys < Wukong::Streamer::AccumulatingReducer
      attr_accessor :key_count

      def formatted_key_count
        "%10d"%key_count.to_i
      end

      # reset the counter to zero
      def reset!
        super
        self.key_count = 0
      end

      # record one more for this key
      def accumulate *vals
        self.key_count += 1
      end

      # emit each key field and the count, tab-separated.
      def finalize
        yield [key, formatted_key_count]
      end
    end

  end
end
