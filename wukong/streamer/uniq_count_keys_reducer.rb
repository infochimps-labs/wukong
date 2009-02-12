module Wukong
  module Streamer
    #
    # Emit each unique key and the count of its occurrences
    #
    class UniqueCountLinesReducer < Wukong::Streamer::AccumulatingReducer
      def format_freq freq
        "%010d"%freq.to_i
      end

      # reset the counter to zero
      def reset!
        self.count = 0
      end

      # record one more for this key
      def accumulate
        self.count += 1
      end

      # emit each key field and the count, tab-separated.
      def finalize
        puts [key, format_count(count)].flatten.join("\t")
      end
    end

  end
end
