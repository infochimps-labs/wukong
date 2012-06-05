module Wukong
  class Runner
    include Gorillib::FancyBuilder
    member     :flow,     Wukong::Dataflow

    def run(slot_name)
      wire_flow
      flow.setup
      drive_flow(slot_name)
      flow.stop
    end

  protected

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

    def drive_flow(slot_name)
      flow.input(slot_name).drive
    end

    def wire_flow
      # flow.set_output sink(:test_sink)
      # flow.set_output sinks.to_a.last
    end
  end
end
