
module Wukong
  class Runner
    include Gorillib::FancyBuilder

  end

  # Run dataflow in pure ruby
  class LocalRunner
    collection :sources
    collection :sinks
    member     :graph

    def run
      wire_graph
      setup
      sources.to_a.first.each do |record|
        graph.process(record)
      end
      stop
    end

protected

    # @returns a list with inputs, graph and outputs, in that order
    def stages
      inputs.to_a.concat([graph]).concat(outputs.to_a)
    end

    def setup
      stages.each{|stage| stage.setup}
    end

    def stop
      stages.each{|stage| stage.stop}
    end

    def wire_graph
      graph.set_input(:output,  sources.to_a.first)
      graph.set_output(:output, sinks.to_a.first)
    end
  end
end
