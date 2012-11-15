require_relative('utils')

module Wukong
  class Processor
    
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

    class Logger < Processor
      field :level, Symbol, :default => :info
      def process(record)
        log.send(level, record)
      end
      register
    end

    class Extract < Processor
      include DynamicGet
      field :part, Whatever, :default => nil
      def process record
        yield get(self.part, record)
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
