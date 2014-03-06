module Wukong
  module Streamer
    #
    # Roll up all records from a given key into a single list.
    #
    class ListReducer < Wukong::Streamer::AccumulatingReducer
      attr_accessor :values

      # start with an empty list
      def start! *args
        @values = []
      end

      # aggregate all records.
      # note that this accumulates the full *record* -- key, value, everything.
      def accumulate *record
        @values << record
      end

      # emit the key and all records, tab-separated
      #
      # you will almost certainly want to override this method to do something
      # interesting with the values (or override accumulate to gather scalar
      # values)
      #
      def finalize
        yield [key, @values.to_flat.join(";")].flatten
      end
    end
  end
end
