module Hanuman
  module Universe

    def self.defined_stages()  @defined_stages  ||= {} ; end
    def self.defined_actions() @defined_actions ||= {} ; end

    def self.stage(stage_name, &blk)
      stage = defined_stages.fetch(stage_name) do
        klass_name = Gorillib::Inflector.camelize(stage_name.to_s).to_sym
        const_defined?(klass_name) ? const_get(klass_name) : const_set(klass_name, Class.new(Hanuman::Stage))
      end
      stage.class_eval(&blk) if block_given?
      defined_stages[stage_name.to_sym] = stage
    end

    def self.graph(graph_name, &blk)
      graph = defined_actions.fetch(graph_name) do      
        klass_name = Gorillib::Inflector.camelize(graph_name.to_s).to_sym
        klass = const_defined?(klass_name) ? const_get(klass_name) : const_set(klass_name, Class.new(Hanuman::Graph))
        klass.receive(:name => graph_name)
      end
      graph.register_stage(graph_name)
      graph.extend self
      graph.instance_eval(&blk) if block_given?
      defined_actions[graph_name.to_sym] = graph    
    end

  end
end
