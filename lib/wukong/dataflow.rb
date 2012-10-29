module Wukong
  class DataflowBuilder < Hanuman::GraphBuilder

    def namespace() Wukong::Dataflow ; end

    def handle_dsl_arguments_for(stage, *args, &action)
      options = args.extract_options!
      stage.merge!(options.merge(action: action).compact)
      stage      
    end
    
  end
  
  class Dataflow < Hanuman::Graph

    def has_input?(stage)
      links.any?{ |link| link.into == stage }
    end
    
    def has_output?(stage)
      links.any?{ |link| link.from == stage }
    end

    def connected?(stage)
      input  = has_input?(stage)  || stages[stage].is_a?(Wukong::Source)
      output = has_output?(stage) || stages[stage].is_a?(Wukong::Sink)
      input && output
    end

    def complete?
      stages.all?{ |(name, stage)| connected? name }
    end

    def setup
      directed_sort.each{ |name| stages[name].setup }
    end

    def run
      stages[directed_sort.first].run
    end

    def stop
      directed_sort.each{ |name| stages[name].stop }
    end

  end
end
