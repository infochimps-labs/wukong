module Hanuman

  Registry = {}
  
  class Interpreter

    def interpret(obj, definition)

    end
    
  end

  def self.add_definition_for(label, klass)
    Registry[label] = -> do
      stage = klass.new(label) 
      @stages << stage 
      stage
    end
  end

  @interpreter = Interpreter.new

  def self.stage(label = nil, &blk)
    Stage.register_stage(label)
  end
  
  def self.graph(label = nil, &blk)
    graph = GraphDefinition.new(label)
    Registry.each_pair do |method_name, method_body|
      graph.define_singleton_method(method_name, &method_body)
    end
    graph.instance_eval(&blk) if block_given?
    GraphDefinition.register_stage(label)
    graph.definition   
  end

end
