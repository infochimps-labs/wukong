module Wukong
  module Streamer
    #
    # Accumulate acts like an insecure high-school kid, for each key adopting in
    # turn the latest value seen. It then emits the last (in sort order) value
    # for that key.
    #
    # For example, to extract the *latest* value for each property, set hadoop
    # to use <resource, item_id, timestamp> as sort fields and <resource,
    # item_id> as key fields.
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
