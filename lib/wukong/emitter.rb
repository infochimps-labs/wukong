module Wukong
  class Emitter < Hanuman::DirectedLink
    
    def initialize(from, into)
      @from = from
      @into = into
      @from.write_attribute(:emitter, self)
    end
    
    def call(record)
      into.process(record)
    end

    def to_s
      "#<#{self.class}(#{from.label} -> #{into.label})>"
    end

  end
  
  Hanuman::LinkFactory.register(:emitter, ->(from_stage, into_stage){ Wukong::Emitter.new(from_stage, into_stage) })
  
end
