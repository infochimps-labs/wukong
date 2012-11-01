module Wukong
  class ProcessorBuilder < Hanuman::StageBuilder

    def namespace() Wukong::Processor ; end

  end

  class Processor < Hanuman::Stage

    field :action, Whatever
    field :log,    Whatever, :default => Log

    # This is a placeholder method intended to be overridden
    def perform_action(*args) ; end 
    
    # The action attribute is turned into the perform action method
    def receive_action(action)
      self.define_singleton_method(:perform_action, &action)
    end

    # This method is called after the processor class has been instantiated
    # but before any records are given to it to process
    def setup
    end

    # This method is called once per record
    # Override this in your subclass
    def process(record)
    end

    # This method is called after all records have been processed
    def stop
    end
  
  end
end
