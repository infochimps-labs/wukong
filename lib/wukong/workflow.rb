module Wukong
  class WorkflowGraph < Hanuman::Graph
  end

  class Workflow  < WorkflowGraph
    has_input
    has_output

    #
    # lifecycle
    #

    def setup
      stages.each_value{|stage| stage.setup}
    end

    def stop
      stages.each_value{|stage| stage.stop}
    end

  end
end
