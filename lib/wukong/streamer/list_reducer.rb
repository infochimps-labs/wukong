module Wukong
  module Streamer
    #
    # Roll up all records from a given key into a single list.
    #
    class ListReducer < Wukong::Streamer::AccumulatingReducer
      attr_accessor :values

      # start with an empty list
      def start! *args
        self.values = []
      end

      # aggregate all values
      def accumulate *record
        self.values << record.to_flat.join(";")
      end

      # emit the key and all values, tab-separated
      def finalize
        yield [key, values].flatten
      end
    end
  end
end
