require_relative("group")

module Wukong
  class Processor
    class Moments < Group

      field :group_by, Whatever

      attr_accessor :measurements

      field :of,      Array,    :default => []
      field :std_dev, :boolean, :default => true

      def get_key record
        super(record) unless (self.group_by || self.by)
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
  end
end

