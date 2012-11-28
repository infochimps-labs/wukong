require_relative("accumulator")
require_relative("../utils")

module Wukong
  class Processor

    class Sort < Accumulator
      
      include DynamicGet
      field :on,        Whatever
      field :reverse,   :boolean, :default => false
      field :numeric,   :boolean, :default => false

      def setup
        super()
        @records = []
      end

      def finalize
        sorted = @records.sort{ |x, y| compare(x, y) }
        sorted.reverse! if reverse
        sorted.each{ |record| yield record }
      end
      
      def get_key(record)
        :__first_group__ # ensures all in the same group
      end
      
      def sortable(record)
        get(self.on, record)
      end

      def accumulate record
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

      register
    end
  end
end
