module Wukong
  module Streamer
    #
    # UniqByLastReducer accepts all records for a given key and emits only the
    # last-seen.
    #
    # It acts like an insecure high-school kid: for each record of a given key
    # it discards whatever record it's holding and adopts this new value. When a
    # new key comes on the scene it emits the last record, like an older brother
    # handing off his Depeche Mode collection.
    #
    # For example, to extract the *latest* value for each property, emit your
    # records as
    #
    #    [resource_type, key, timestamp, ... fields ...]
    #
    # then set :sort_fields to 3 and :partition_fields to 2.
    #
    class UniqByLastReducer < Wukong::Streamer::AccumulatingReducer
      attr_accessor :final_value

      #
      # Use first two fields as keys by default
      #
      def get_key *vals
        vals[0..1]
      end

      #
      # Adopt each value in turn: the last one's the one you want.
      #
      def accumulate *vals
        self.final_value = vals
      end

      #
      # Emit the last-seen value
      #
      def finalize
        yield final_value if final_value
      end

      #
      # Clear state on reset
      #
      def start! *args
        self.final_value = nil
      end
    end
  end
end
