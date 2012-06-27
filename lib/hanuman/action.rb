module Hanuman
  class Action < Stage

    magic :input,  Hanuman::Stage
    magic :output, Hanuman::Stage

    def inputs()  [input]  ; end
    def outputs() [output] ; end

    def set_input(slot_name, stage)
      raise ArgumentError, "there's only one input (':default') on #{self}" unless slot_name == :default
      write_attribute(:input, stage)
    end
    def set_output(slot_name, stage)
      raise ArgumentError, "there's only one output (':default') on #{self}" unless slot_name == :default
      write_attribute(:output, stage)
    end

    def self.register_action(meth_name=nil, &block)
      meth_name ||= stage_type ; klass = self
      Hanuman::Graph.send(:define_method, meth_name) do |*args, &block|
        begin
          klass.make(graph=self, *args, &block)
        rescue StandardError => err ; err.polish("adding #{meth_name} to #{self.name} on #{args}") rescue nil ; raise ; end
      end
    end

    def self.make(graph, *args, &block)
      stage = receive(*args)
      graph.set_stage(stage)
      stage.receive!(&block)
      stage
    end

  end
end
