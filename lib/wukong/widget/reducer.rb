module Wukong
  class Processor

    module DynamicGet

      def self.included klass
        klass.send(:field, :separator, String,   :default => "\t")
      end
      
      def get field, obj
        return unless field
        case
        when field.is_a?(Fixnum) || field.to_s.to_i > 0
          # assume delimited
          obj.split(separator)[field]
        when field.to_s.to_i == 0
          # assume complex field so it's a Hash, try JSON
          begin
            json = MultiJson.load(obj)
            json[field.to_s]
          rescue MultiJson::DecodeError => e
            nil
          end
        end
      end

    end

    class Count < Processor
      def setup
        @count = 0
      end

      def process(record)
        @count += 1
      end

      def finalize
        yield @count
      end

      register
    end

    # This is just a demo class, use only with small data
    class Sort < Processor
      
      include DynamicGet

      field :on,        Whatever, :default => nil
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
    
    class Group < Processor

      include DynamicGet

      field :on,        Whatever, :default => nil

      def process record
        start(record) unless defined?(@key)
        key = get_key(record)
        if key != @key
          finalize { |record| yield record }
          start(record)
        else
          accumulate(record)
        end
      end

      def accumulate record
        @group << record
      end

      def get_key(record)
        get(self.on, record) || record
      end
      
      def start(record)
        @group = [record]
        @key   = get_key(record)
      end

      def finalize()
        yield({ :group => @key, :count => @group.size })
      end

      register
    end

    class GroupStats < Group

      field :measure, Array,    :default => []
      field :count,   :boolean, :default => true
      field :sum,     :boolean, :default => true
      field :mean,    :boolean, :default => true
      field :std_dev, :boolean, :default => true

      def accumulate record
        values = {}
        measure.each do |field|
          value = get(field, record)
          values[field] = value.to_f if value
        end
        @group << values
      end

      def finalize
        stats = {}
        
        measure.each do |field|
          stats[field] = {}
          
          c = 0
          s = 0
          @group.each do |values|
            value = values[field]
            next unless value
            c += 1
            s   += value
          end
          m = s / c if c > 0
          
          stats[field][:count] = c if count
          stats[field][:sum]   = s if sum
          stats[field][:mean]  = m if mean
          
          if m && self.mean && self.std_dev
            v = 0
            @group.each do |values|
              value = values[field]
              next unless value
              v += (value - m)**2
            end
            stats[field][:std_dev] = Math.sqrt(v)
          end
          
        end
      end
      register
    end

  end
end
