module Hanuman
  class Graph < Action

    def stages() @stages ||= {}  ; end
    def edges()  @edges  ||= []  ; end

    def ready?
      stages.values.all?(&:ready?)
    end

    def outlink(stage, link_name)
      set_stage(stage, :output)
      links[:output] = stage
    end

    def inlink(stage, link_name)
      set_stage(stage, :input)
      stage.outlink(stages[:input], :input)
    end

    def connect(from, other)
      from.outlink(other, :output)
      from.inlink(other, :input)
      edges << [ from.label, other.label ]
      other
    end

    def set_stage(stage, stage_name)
      stages[stage_name] = stage
      stage
    end
  end
end
