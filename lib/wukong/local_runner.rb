module Wukong
  class Runner
    include Gorillib::FancyBuilder

    collection :sources,  Wukong::Source
    collection :sinks,    Wukong::Sink
    member     :flow,     Wukong::Dataflow
    
    def run
      wire_flow
      setup
      drive_flow
      stop
    end

    def setup
      stages.each{|stage| stage.setup}
    end

    def stop
      stages.each{|stage| stage.stop}
    end

  protected
    
    # @return a list with inputs, flow and outputs, in that order
    def stages
      [sources.to_a, flow, sinks.to_a].flatten
    end

    # Connect sources, sinks, flows and so forth. On return, the topology of the graph should be in place.
    # Override in your subclass
    #
    # @abstract
    def wire_flow
    end

    # Launch the flow -- sources be each'ing, processors be process'n
    # Override in your subclass
    #
    # @abstract
    def drive_flow
      puts flow
    end
  end

  # Run dataflow in pure ruby
  class LocalRunner < Runner

  protected

    def drive_flow
      sources.to_a.first.each do |record|
        flow.process(record)
      end
    end

    def wire_flow
      # flow.set_output sink(:test_sink)
      flow.set_output sinks.to_a.last
    end
  end
end
