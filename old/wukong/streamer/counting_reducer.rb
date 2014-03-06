module Wukong
  module Streamer
    #
    # Emit each unique key and the count of its occurrences
    #
    class CountingReducer < Wukong::Streamer::AccumulatingReducer

      # reset the counter to zero
      def start! *args
        @count = 0
      end

      # record one more for this key
      def accumulate *vals
        @count += 1
      end

      # emit each key field and the count, tab-separated.
      def finalize
        yield [key, @count]
      end
    end

  end
end
