require 'gorillib/string/human'
module Hanuman

  Stage.class_eval do
    class_attribute :draw_shape
    self.draw_shape = :record

    def to_graphviz(gv, draw_edges=true)
      gv.node(self.fullname,
        :label    => name,
        :shape    => draw_shape)
      inputs.each_value do |input|
        gv.edge(input.fullname, fullname)
      end
    end
  end

  ::Wukong::Workflow::Command.class_eval do
    self.draw_shape = :record

    def to_graphviz(gv, draw_edges=true)
      gv.node(self.fullname,
        :label    => name,
        :inslots  => inputs.to_a.map{|slot|  slot.name},
        :outslots => outputs.to_a.map{|slot| slot.name},
        :shape    => draw_shape
        )
      inputs.each_value do |input|
        gv.edge(input.fullname, fullname)
      end
    end
  end

  Resource.class_eval do
    self.draw_shape = :Mrecord
  end

  class Graph < Action
    self.draw_shape = :record
    def to_graphviz(gv)
      gv.graph(fullname, :label => name) do |gv2|
        stages.each_value{|stage| stage.to_graphviz(gv2) }
      end
      super(gv, false)
    end
  end

  module ::Wukong::Universe
    def to_graphviz
      gv = Hanuman::Graphvizzer::Universe.new(
        :name => self.name,
        :orient => :TD, :engine => :dot)
      @workflows.each do |_, workflow|
        workflow.to_graphviz(gv)
      end
      gv
    end
  end

end
