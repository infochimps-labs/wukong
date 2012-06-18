module Hanuman
  class Action < Stage

    # Called after the graph is constructed, before the flow is run
    def setup
    end

    # Called to signal the flow should stop. Close any open connections, flush
    # buffers, stop supervised projects, etc.
    def stop
    end

    def self.register_action(meth_name=nil, &block)
      meth_name ||= handle ; klass = self
      Hanuman::Graph.send(:define_method, meth_name) do |*args, &block|
        begin
          klass.make(workflow=self, *args, &block)
        rescue StandardError => err ; err.polish("adding #{meth_name} to #{self.name} on #{args}") rescue nil ; raise ; end
      end
    end

    def self.make(workflow, *args, &block)
      stage = receive(*args)
      workflow.add_stage stage
      stage.receive!(&block)
      stage
    end
  end

end
