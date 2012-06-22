module Hanuman
  class Action < Stage

    # Called after the graph is constructed, before the flow is run
    def setup
    end

    # Called to signal the flow should stop. Close any open connections, flush
    # buffers, stop supervised projects, etc.
    def stop
    end
    
    # The last of the trifecta of methods that constitute an Action.
    def process
    end

    def self.register_action(meth_name = nil, &block)
      meth_name ||= handle ; klass = self
      Hanuman::Graph.send(:define_method, meth_name) do |*args, &block|
        begin
          stage = klass.make(graph = self, meth_name, *args, &block)
          set_stage(meth_name.to_sym, stage)
          stage 
        rescue StandardError => err ; err.polish("adding #{meth_name} to #{self.name} on #{args}") rescue nil ; raise ; end
      end
    end
  end

end
