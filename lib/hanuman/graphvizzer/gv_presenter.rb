require 'hanuman/graphvizzer/gv_models'

module Hanuman

  Stage.class_eval do
    class_attribute :draw_shape
    self.draw_shape = :record

    def to_graphviz(gv)
      gv.node(self.graph_id,
        :label    => name,
        :shape    => draw_shape,
        # :inslots  => consumes.to_a.map{|slot| slot.name },
        # :outslots => produces.to_a.map{|slot| slot.name },
        )
    end
  end

  Resource.class_eval do
    self.draw_shape = :Mrecord
  end

  module ::Wukong::Universe
    def to_graphviz
      gv = Hanuman::Graphvizzer::Universe.new(:name => self.name)
      @workflows.each do |_, workflow|
        workflow.to_graphviz(gv)
      end
      @dataflows.each do |_, dataflow|
        dataflow.to_graphviz(gv)
      end
      gv
    end
  end

  Graph.class_eval do
    self.draw_shape = :record

    def to_graphviz(gv)
      gv.graph(graph_id, :label => name) do |gv2|
        stages.each_value{|stage| stage.to_graphviz(gv2) }
        #
        edges.each_pair do |from, into|
          gv2.edge(from.graph_id, into.graph_id)
        end
      end
      # super(gv)
    end
  end

end
