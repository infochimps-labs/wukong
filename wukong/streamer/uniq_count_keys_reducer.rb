module Wukong
  module Streamer
    #
    # Emit each unique key and the count of its occurrences
    #
    class UniqCountKeysReducer < Wukong::Streamer::AccumulatingReducer
      attr_accessor :key_count

      def formatted_key_count
        "%010d"%key_count.to_i
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
        puts [curr_key, formatted_key_count].flatten.join("\t")
      end
    end

  end
end
