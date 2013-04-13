module Wukong

  class Dataflow < Hanuman::Tree

    def self.description desc=nil
      @description = desc if desc
      @description
    end
  end
  
  class DataflowBuilder < Hanuman::TreeBuilder

    def description desc=nil
      @description = desc if desc
      @description
    end
    
    def namespace() Wukong::Dataflow ; end

    def handle_dsl_arguments_for(stage, *args, &action)
      options = args.extract_options!
      stage.merge!(options.merge(action: action).compact)
      stage.graph = self
      stage
    end
  
    def method_missing(name, *args, &blk)
      if stages[name]
        handle_dsl_arguments_for(stages[name], *args, &blk)
      else
        super
      end
    end
    
  end
end
