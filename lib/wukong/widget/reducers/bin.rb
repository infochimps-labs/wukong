module Wukong
  class Processor
    class Bin < Accumulator
      
      field :num_bins,    Integer
      field :edges,       Array
      field :min,         Float
      field :max,         Float

      include DynamicGet
      field :by,          Whatever

      field :logarithmic, :boolean, :default => false
      field :normalize,   :boolean, :default => false
      
      attr_accessor :values, :bins, :counts, :total_count
      
      def setup
        super()
        self.values      = []
        self.bins        = []
        self.counts      = []
        self.total_count = 0
        if edges.nil?
          set_edges_from_min_max_and_num_bins! if min && max && num_bins
        else
          set_bins_and_counts_from_edges!
        end
      end

      def get_key record
        :__first__group__
      end

      def accumulate record
        value = (value_from(record) or return)
        self.total_count += 1
        if bins?
          add_to_some_bin(value)
        else
          self.min ||= value
          self.min = value if value < min
          self.max ||= value
          self.max = value if value > max
          self.values << value
        end
      end

      def finalize
        bin! unless bins?
        counts.each_with_index do |count, index|
          bin  = bins[index]
          record = {bin: bin, count: log_if_necessary(count)}
          if normalize && total_count > 0
            record[:frequency] = log_if_necessary((count.to_f / total_count.to_f))
          end
          yield MultiJson.dump(record)
        end
      end
      
      def receive_min new_min
        raise Error.new("The minimum value must be strictly less than the maximum value") if max && new_min.to_f >= max
        @min = new_min.to_f
      end

      def receive_max new_max
        raise Error.new("The maximum value must be strictly greater than the minimum value") if min && new_max.to_f <= min
        @max = new_max.to_f
      end
      
      def receive_num_bins n
        raise Error.new("The number of bins must be a postive-definite integer") if n.to_i <= 0
        @num_bins = n.to_i
      end

      def receive_edges es
        @edges = case es
                 when String then es.split(',')
                 when Array  then es
                 end.map(&:to_f).sort
        set_bins_and_counts_from_edges! if @edges
        @edges
      end

      private

      def set_num_bins_from_total_count!
        self.num_bins = Math.sqrt(total_count).to_i
      end

      def set_bins_and_counts_from_edges!
        @bins = [].tap do |b|
          edges[0..-2].each_with_index do |edge, index|
            b << [edge, edges[index+1]]
          end
        end
        @counts = bins.length.times.map { 0 }
      end

      def set_edges_from_min_max_and_num_bins!
        diff    = (max - min) / num_bins
        e       = [min]
        current = min + diff
        while current < max
          e << current
          current += diff
        end
        e << max
        self.edges = e
        set_bins_and_counts_from_edges!
      end

      def bins?
        bins && (! bins.empty?)
      end

      def value_from record
        val = get(self.by, record)
        return unless val
        val.to_f rescue nil
      end

      def log_if_necessary val
        if logarithmic && val > 0
          Math.log(val)
        else
          val
        end
      end
      
      def bin!
        set_num_bins_from_total_count! unless self.num_bins
        set_edges_from_min_max_and_num_bins!
        until values.empty?
          value = values.shift
          add_to_some_bin(value.to_f) if value
        end
      end

      def add_to_some_bin value
        # FIXME optimize this O(n) algorithm...
        bins.each_with_index do |bin, index|
          lower, upper = bin
          if value >= lower && value < upper
            counts[index] += 1
            return
          end
        end
        counts[-1] += 1         # if it's the maximal element
      end

      register
    end
  end
end
