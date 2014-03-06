module Wukong
  module Streamer
    #
    # Emit each unique key and the count of its occurrences
    #
    class SummingReducer < Wukong::Streamer::AccumulatingReducer
      attr_accessor :summing_elements
      attr_accessor :sums      

      # reset the counter to zero
      def start! *args
        self.sums = summing_elements.map{ 0 }
      end

      # record one more for this key
      def accumulate *fields
        vals = fields.values_at( *summing_elements )
        vals.each_with_index{|val,idx| self.sums[idx] += val.to_i }
      end

      # emit each key field and the count, tab-separated.
      def finalize
        yield [key, sums].flatten
      end
    end

  end
end

