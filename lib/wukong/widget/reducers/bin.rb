module Wukong
  class Processor

    # A widget for binning input data.  Will emit
    #
    # 
    #
    # @example Binning some input data on the command-line
    #
    #   $ cat input
    #   0.94628
    #   0.03480
    #   0.74418
    #   ...
    #   $ cat input | wu-local bin
    #
    #   0.02935	0.12638500000000003	7
    #   0.12638500000000003	0.22342000000000004	11
    #   0.22342000000000004	0.32045500000000005	15
    #
    # @example Control how the bins are defined and displayed
    #
    #   $ cat input | wu-local bin --min=0.0 --max=1.0 --num_bins=10 --precision=1
    #   0.0	0.1	10.0
    #   0.1	0.2	12.0
    #   0.2	0.3	8.0
    #   ...
    #
    # @example Include an additional column of normalized (fractional) counts
    # 
    #   $ cat input | wu-local bin --min=0.0 --max=1.0 --num_bins=10 --precision=1 --normalize
    #   0.0	0.1	10.0	0.3
    #   0.1	0.2	12.0	0.36
    #   0.2	0.3	8.0	0.24
    #   ...
    #
    # @example Make a log-log histogram
    #
    #   $ cat input | wu-local bin --log_bins --log_counts
    #   1.000	3.162	1.099
    #   3.162	10.000	1.946
    #   10.000	31.623	3.045
    #   31.623	100.000	4.234
    #
    # This widget works nicely with the Extract widget at the end of a
    # data flow:
    #
    # @example Use the bin at the end of a dataflow
    #
    #   Wukong.processor(:bins_at_end) do
    #     ... | extract(part: 'age') | bin(num_bins: 10)
    #   end
    #
    # @see Accumulator
    # @see Extract
    class Bin < Accumulator
      
      field :num_bins,    Integer
      field :edges,       Array
      field :min,         Float
      field :max,         Float

      field :format_string, String
      field :precision,     Integer, :default => 3

      include DynamicGet
      field :by,          Whatever

      field :log_bins,    :boolean, :default => false
      field :log_counts,  :boolean, :default => false
      field :base,        Float,    :default => Math::E
      
      field :normalize,   :boolean, :default => false

      # The accumulated values
      attr_accessor :values

      # The bins (pairs of edges)
      attr_accessor :bins

      # The value counts within each bin.
      attr_accessor :counts

      # The total number of accumulated values.
      attr_accessor :total_count

      # Initializes all storage.  If we can calculate bins in advance,
      # do so now.
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

      # Keep all records in the same "group", at least from the
      # Accumulator's perspective.
      #
      # @param [Object] record
      # @return [:__first__group__]
      def get_key record
        :__first__group__
      end

      # Accumulates a single `record`.
      #
      # First we extract the value from the record.  If we already
      # have bins, add the value to the appropriate bin.  Otherwise,
      # store the value, updating any properties like `max` or `min`
      # as necessary.
      #
      # @param [Object] record
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

      # Emits each bin with its edges and count.  Adds the normalized
      # count if requested.
      #
      # Will bins the values if we haven't done so on the fly already.
      #
      # @yield [lower, upper, count, normalized_count]
      # @yieldparam [String] lower the lower (left) edge of the bin
      # @yieldparam [String] upper the upper (right) edge of the bin
      # @yieldparam [String] count the (logarithmic if requested) count of values in the bin
      # @yieldparam [String] normalized_count the (logarithmic if requested) normalized count of values in the bin if requested
      def finalize
        bin! unless bins?
        counts.each_with_index do |count, index|
          bin  = bins[index]
          bin << log_count_if_necessary(count)
          if normalize && total_count > 0
            bin << log_count_if_necessary((count.to_f / total_count.to_f))
          end
          yield bin.map { |n| format(n) }.join("\t")
        end
      end

      # Formats `n` so it's readable and compact.
      #
      # If this widget is given an explicit `format_string` then it
      # will be used here (the value of `format_string` should have a
      # slot for a float).
      #
      # Otherwise, large (or small) numbers will be formatted in
      # scientific notation while "medium numbers" (0.001 < |n| <
      # 1000) are merely printed, all with the given `precision`.
      #
      # @param [Float] n
      # @return [String]
      def format n
        case
        when format_string
          format_string % n
        when n == 0.0
          0.0
        when n.abs > 1000 || n.abs < 0.001
          "%#{precision}.#{precision}E" % n
        else
          "%#{precision}.#{precision}f" % n
        end
      end

      # Bins the accumulated values.
      #
      # @see #bins?
      def bin!
        set_num_bins_from_total_count! unless self.num_bins
        set_edges_from_min_max_and_num_bins!
        until values.empty?
          value = values.shift
          add_to_some_bin(value.to_f) if value
        end
      end
      
      # Does this widget have a populated list of bins?
      #
      # @return [true, false]
      def bins?
        bins && (! bins.empty?)
      end

      # Get a value from a given `record`.
      #
      # @param [Object] record
      # @return [Float, nil]
      def value_from record
        val = get(self.by, record)
        return unless val
        val.to_f rescue nil
      end

      # Returns `val`, taking a logarithm to the appropriate base if
      # required.
      #
      # @param [Float] val
      # @return [Float] the original value or its logarithm if required
      def log_count_if_necessary val
        log_counts ? log_if_possible(val) : val
      end

      # Returns the logarithm of the given `val` if possible.
      #
      # Will return the original value if negative.
      #
      # @param [Float] val
      # @return [Float]
      def log_if_possible val
        val > 0 ? Math.log(val, base) : val
      end
      
      private

      # :nodoc
      def receive_min new_min
        raise Error.new("The minimum value must be strictly less than the maximum value") if max && new_min.to_f >= max
        @min = new_min.to_f
      end

      # :nodoc
      def receive_max new_max
        raise Error.new("The maximum value must be strictly greater than the minimum value") if min && new_max.to_f <= min
        @max = new_max.to_f
      end

      # :nodoc
      def receive_num_bins n
        raise Error.new("The number of bins must be a postive-definite integer") if n.to_i <= 0
        @num_bins = n.to_i
      end

      # :nodoc
      def receive_edges es
        @edges = case es
                 when String then es.split(',')
                 when Array  then es
                 end.map(&:to_f).sort
        set_bins_and_counts_from_edges! if @edges
        @edges
      end
      
      # :nodoc
      def set_num_bins_from_total_count!
        self.num_bins = Math.sqrt(total_count).to_i
      end

      # :nodoc
      def set_bins_and_counts_from_edges!
        @bins = [].tap do |b|
          edges[0..-2].each_with_index do |edge, index|
            b << [edge, edges[index+1]]
          end
        end
        @counts = bins.length.times.map { 0 }
      end

      # :nodoc
      def set_edges_from_min_max_and_num_bins!
        e = []
        
        if log_bins
          bin_min  = log_if_possible(min)
          bin_max  = log_if_possible(max)
        else
          bin_min = min
          bin_max = max
        end
        
        bin_diff = (bin_max - bin_min) / num_bins
        e << bin_min
        current = bin_min + bin_diff
        while current < bin_max
          e << current
          current += bin_diff
        end
        e << bin_max

        if log_bins
          self.edges = e.map { |n| Math.exp(n) }
        else
          self.edges = e
        end
        set_bins_and_counts_from_edges!
      end

      # :nodoc:
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
