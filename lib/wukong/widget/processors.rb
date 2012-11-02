module Wukong
  class Processor
    
    class Null < Processor
      def process(record)
        # ze goggles... zey do nussing!
      end    
      register
    end
    
    # Until further notice, this processor is unusable due to the invocation of yield
    # class Foreach < Processor
    #   def process(record, &blk)
    #     perform_action(record, &blk)
    #   end
    #   register
    # end

    class Map < Processor
      def process(record)
        yield perform_action(record)
      end
      register
    end
    
    class Flatten < Processor
      def process(records)
        records.respond_to?(:each) ? records.each{ |record| yield(record) } : yield(records)
      end
      register
    end
    
    class Filter < Processor
      def process(record) yield(record) if select?(record) ; end
      def reject?(record) not select?(record)              ; end
      def select?(record) true                             ; end
    end

    class IncludeAll < Filter
      register
    end
    
    class ExcludeAll < Filter
      def select?(record) false ; end
      register
    end

    class RegexpFilter < Filter
      field :match, Regexp
      def select?(record)
        self.match.match perform_action
      end
      register(:regexp)
    end
    
    class NotRegexpFilter < Filter
      def select?(record)
        not record.match perform_action
      end
      register(:not_regexp)      
    end

    class Limit < Filter
      field :max, Float, :default => Float::INFINITY
      def select?(record)
        @count ||= 0.0
        keep = @count < max
        @count += 1
        keep
      end
      register
    end

    class Select < Filter
      def select?(record)
        perform_action(record)
      end
      register
    end
    
    class Reject < Filter
      def select?(record)
        not perform_action(record)
      end
      register
    end

    class Logger < Processor
      field :level, Symbol, :default => :info
      def process(record)
        log.send(level, record)
      end
      register
    end

    # This is just a demo class, use only with small data
    class Sort < Processor
      field :on,        Whatever, :default => nil
      field :separator, String,   :default => "\t"
      field :reverse,   :boolean, :default => false
      field :numeric,   :boolean, :default => false

      def setup()
        @records = []
      end
      
      def sortable(record)
        case 
        when self.on.nil? && record.respond_to?(:<=>) then record          
        when record.respond_to?(self.on.to_s)         then record.send(self.on.to_s)
        when self.on && record.is_a?(String)          then record.split(separator)[self.on.to_i]
        when record.respond_to(:[])                   then record[self.on]          
        end
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
  end
end
