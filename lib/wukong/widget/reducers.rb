require_relative('utils')
module Wukong
  class Processor

    # This is just a demo class, use only with small data
    class Sort < Processor
      
      include DynamicGet
      field :on,        Whatever
      field :reverse,   :boolean, :default => false
      field :numeric,   :boolean, :default => false

      def setup()
        @records = []
      end
      
      def sortable(record)
        get(self.on, record)
      end
      
      def process(record)        
        @records << record
      end
      
      def compare(x, y)
        a = (sortable(x) or return -1) 
        b = (sortable(y) or return  1)
        if numeric
          a = a.to_f ; b = b.to_f
        end
        a <=> b
      end

      def finalize()
        sorted = @records.sort{ |x, y| compare(x, y) }
        sorted.reverse! if reverse
        sorted.each{ |record| yield record }
      end
      register
    end

    class Accumulator < Processor

      attr_accessor :key, :group

      def setup
        @key   = :__first_group__
      end
      
      def process(record)
        this_key = get_key(record)
        if this_key != self.key
          finalize { |record| yield record }  unless self.key == :__first_group__
          self.key = this_key
          start record
        end
        accumulate(record)
      end

      def start record
      end
      
      def get_key record
        :__first_group__
      end
      
      def accumulate record
      end
    end

    class Count < Accumulator

      attr_accessor :size

      def setup
        super()
        @size = 0
      end

      def accumulate record
        self.size += 1
      end

      def finalize
        yield self.size
      end

      register
    end
    
    class Group < Count

      include DynamicGet
      field :by, Whatever

      def get_key(record)
        get(self.by, record)
      end

      def finalize
        yield({ :group => key, :count => size })
      end

      def start record
        self.size = 0
      end
      
      register
    end

    class GroupConcat < Group
      attr_accessor :members
      
      def setup
        super()
        @members = []
      end

      def start record
        super(record)
        self.members = []
      end

      def finalize
        yield({:group => key, :count => size, :members => members})
      end

      def accumulate record
        super(record)
        self.members << record
      end
      register
    end

    class Moments < Group

      field :group_by, Whatever

      attr_accessor :measurements

      field :of,      Array
      field :std_dev, :boolean, :default => true

      def get_key record
        return :__first_group__ unless (self.group_by || self.by)
        get(self.group_by || self.by, record)
      end

      def receive_of o
        @of = case o
        when String then o.split(',')
        when Array  then o
        else []
        end
      end

      def start record
        super(record)
        @measurements = {}.tap do |m|
          self.of.each do |property|
            m[property] = []
          end
        end
      end

      def accumulate record
        super(record)
        self.of.each do |property|
          if raw = get(property, record)
            self.measurements[property] << (raw.to_f rescue next)
          end
        end
      end
      
      def results
        {}.tap do |r|
          measurements.each_pair do |property, values|
            r[property] = {}
            next if values.empty?
            count               = values.size.to_f
            r[property][:count] = count.to_i
            
            mean               = values.inject(0.0) { |sum, value| sum += value } / count
            r[property][:mean] = mean
            if std_dev
              variance    = values.inject(0.0) { |sum, value| diff = (value - mean) ; sum += diff * diff } / count
              std         = Math.sqrt(variance)
              r[property][:std_dev] = std
            end
          end
        end
      end

      def finalize
        super() do |record|
          yield record.merge(:results => results) if record
        end
      end
      
      register
    end

    class Bin < Accumulator

      include DynamicGet
      field :on,          Whatever
      field :logarithmic, :boolean, :default => false
      field :num_bins,    Integer

      attr_accessor :min, :max, :values, :bins, :counts
      
      def setup
        super()
        @values = []
        @min    =  Float::INFINITY
        @max    = -Float::INFINITY
        @bins   = []
        @counts = []
      end

      def accumulate record
        if raw = get(self.on, record)
          value = (raw.to_f rescue return)
          value = (Math.log(value) rescue return) if logarithmic
          self.min = value if value < min
          self.max = value if value > max
          self.values << value
        end
      end

      def counts_and_bins
        counts.each_with_index do |count, index|
          lower, upper = bins[index], bins[index+1]
          yield count, [lower,upper]
        end
      end

      def bin!
        return if values.empty?
        n = (num_bins || Math.sqrt(values.size))
        diff = (max - min) / n
        return unless diff > 0
        self.bins   = [min]
        self.counts = [0]
        current     = min + diff
        while current < max
          self.bins   << current
          self.counts << 0
          current += diff
        end
        self.bins << max

        values.each do |value|
          bins[0..-2].each_with_index do |bin, index|
            next_bin = [bin + diff,max].min
            case
            when value >= bin && value < next_bin
              self.counts[index] += 1
              break
            when value == max
              self.counts[-1] += 1
              break
            end
          end
        end
      end

      def finalize
        bin!
        counts_and_bins do |count, bin|
          yield({:bin => bin, :count => count })
        end
      end
      register
    end
  end
end
