module Wukong
  class WorkflowGraph < Hanuman::Graph
  end

  class Workflow  < WorkflowGraph
    include Hanuman::IsOwnInputSlot
    include Hanuman::IsOwnOutputSlot

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
