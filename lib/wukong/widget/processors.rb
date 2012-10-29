module Wukong
  class Processor

    class Null < Processor
      def process(record)
        # ze goggles... zey do nussing!
      end    
      register
    end
    
    class Foreach < Processor
      def process(record)
        perform_action(record)
      end
      register
    end

    class Map < Processor
      def process(record)
        emit perform_action(record)
      end
      register
    end
    
    class Flatten < Processor
      def process(records)
        records.respond_to?(:each) ? records.each{ |record| emit(record) } : emit(records)
      end
      register
    end
    
    class Filter < Processor
      def process(record) emit(record) if select?(record) ; end
      def reject?(record) not select?(record)             ; end
      def select?(record) true                            ; end
    end

    class IncludeAll < Filter
      register
    end
    
    class ExcludeAll < Filter
      def select?(record) false ; end
      register
    end

    class RegexpFilter < Filter
      def select?(record)
        record.match perform_action
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
  end
end
