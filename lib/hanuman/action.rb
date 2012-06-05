module Hanuman

  class Action < Stage
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
