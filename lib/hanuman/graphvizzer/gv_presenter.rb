require 'hanuman/graphvizzer/gv_models'

module Hanuman

  Stage.class_eval do
    class_attribute :draw_shape
    self.draw_shape = :record

    def graphviz_id
      graph_id
    end

    def gv_into_label() %Q{"#{graphviz_id}":"i"}  ; end
    def gv_from_label() %Q{"#{graphviz_id}":"_o"} ; end

    def to_graphviz(gv)
      gv.node(self.graphviz_id,
        :label    => name,
        :shape    => draw_shape,
        )
    end
  end

  Product.class_eval do
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
      gv.graph(graphviz_id, :label => name) do |gv2|
        stages.each_value{|stage| stage.to_graphviz(gv2) }
        outslots.each_value{|outslot| gv2.node(self.graphviz_id, label: outslot.name, :outslots => [outslot.name]) }
        #
        edges.each_value do |edge|
          gv2.edge(edge[:from].gv_from_label, edge[:into].gv_into_label)
        end
      end
    end
  end

  InputSlot.class_eval do
    def gv_into_label() %Q{"#{stage.graphviz_id}":"#{name}"}  ; end
    def gv_from_label() %Q{"#{stage.graphviz_id}":_o}         ; end
  end

  OutputSlot.class_eval do
    def to_graphviz(gv)
      gv.node(self.graphviz_id, label: name, shape: :Mrecord)
    end
    def graphviz_id() graph_id ;  end
    def gv_into_label() %Q{"#{stage.graphviz_id}":i}  ; end
    def gv_from_label() %Q{"#{stage.graphviz_id}":"_#{name}"} ; end
  end

end
