module Wukong
  module Streamer
    #
    # Emit each unique key and the count of its occurrences
    #
    class ListReducer < Wukong::Streamer::AccumulatingReducer
      attr_accessor :values

      # reset the counter to zero
      def start! *args
        self.values = []
      end

      # record one more for this key
      def accumulate *record
        self.values << record
      end
    end
  end
end
