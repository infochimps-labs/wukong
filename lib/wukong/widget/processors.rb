require_relative('utils')

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

    class Extract < Processor
      include DynamicGet
      def process record
        yield get(self.on, record)
      end
      register
    end
    
    class Topic < Processor
      field :topic, Symbol
      def process(record)
        yield perform_action(record)
      end

      def perform_action(record)
        assign_topic(record, topic)
      end      

      def assign_topic(record, topic_name)
        record.define_singleton_method(:topic){ topic_name }
        record
      end
      register
    end
  end
end
