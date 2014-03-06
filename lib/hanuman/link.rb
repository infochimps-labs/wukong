module Hanuman
  class LinkFactory

    Registry = {
      simple: ->(from_stage, *into_stage){ DirectedLink.new(from_stage, *into_stage) }
    }
    
    class << self
    
      def connect(label, from_stage, *into_stage)
        Registry[label].call(from_stage, *into_stage)
      end
      
      def register(label, factory_method)
        Registry[label] = factory_method
      end

    end    
  end
  
  class DirectedLink

    attr_accessor :from, :into
    
    def initialize(from, into)
      @from = from
      @into = into
    end

    def to_s
      "#<#{self.class}(#{from.to_s} -> #{into.to_s})>"
    end
    
  end
end
