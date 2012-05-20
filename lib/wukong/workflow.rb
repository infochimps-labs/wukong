module Wukong
  class WorkflowGraph < Hanuman::Graph
  end

  class Workflow  < WorkflowGraph
    collection :inputs,  Hanuman::Stage
    collection :outputs, Hanuman::Stage

    def set_output(sink)
      stages.to_a.last.set_output :_, sink
    end

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
