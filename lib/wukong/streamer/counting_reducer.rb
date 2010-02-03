module Wukong
  module Streamer

    #
    # Count the number of records for each key.
    #
    class CountingReducer < AccumulatingReducer
      attr_accessor :count

      # start the sum with 0 for each key
      def start! *_
        self.count = 0
      end
      # ... and count the number of records for this key
      def accumulate *_
        self.count += 1
      end
      # emit [key, count]
      def finalize
        yield [key, count].flatten
      end
    end

  end
end
