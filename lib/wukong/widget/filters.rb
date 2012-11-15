module Wukong
  class Processor

    class Null < Processor
      def process(record)
        # ze goggles... zey do nussing!
      end    
      register
    end
    
    class Filter < Processor
      def process(record) yield(record) if select?(record) ; end
      def reject?(record) not select?(record)              ; end
      def select?(record) true                             ; end
      register
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
        return true unless match
        match =~ record.to_s
      end
      register(:regexp)
    end
    
    class NotRegexpFilter < RegexpFilter
      def select?(record)
        return true unless match
        not match =~ record.to_s
      end
      register(:not_regexp)      
    end

    class Limit < Filter
      field :max, Integer, :default => Float::INFINITY
      
      def setup
        @count = 0
      end
      
      def select?(record)
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
