require 'hanuman/graphvizzer/gv_models'

module Hanuman

  Stage.class_eval do
    class_attribute :draw_shape
    self.draw_shape = :record

    def graphviz_id
      graph_id
    end


    def gv_into_label() warn [self, self.class.ancestors]; %Q{"#{graphviz_id}":"i"}  ; end
    def gv_from_label() warn [self, self.class.ancestors]; %Q{"#{graphviz_id}":"_o"} ; end

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
      @workflows.each_value do |workflow|
        workflow.to_graphviz(gv)
      end
      @dataflows.each_value do |dataflow|
        dataflow.to_graphviz(gv)
      end
      gv
    end
  end

  Graph.class_eval do
    self.draw_shape = :record

    def to_graphviz(gv)
      gv.graph(graphviz_id, :label => name) do |gv2|
        inslots.each_value{|slot|  slot.to_graphviz(gv2) if slot.wired? }

        stages.each_value{|stage|  stage.to_graphviz(gv2) }

        outslots.each_value{|slot| slot.to_graphviz(gv2) if slot.wired? }
        #
        edges.each_value do |edge|
          gv2.edge(edge[:from].gv_from_label, edge[:into].gv_into_label)
        end
      end
    end
  end

  module Hanuman::Slottable
    def to_graphviz(gv)
      super.tap{|node| node.receive!(
          :inslots  => inslots.to_a.map{|slot|  slot.name },
          :outslots => outslots.to_a.map{|slot| slot.name },
          ) }
      end
  end

  module InputSlotted
    def gv_into_label() %Q{"#{graphviz_id}":"i"}  ; end
  end
  module OutputSlotted
    def gv_from_label() %Q{"#{graphviz_id}":"_o"} ; end
  end

  Slot.class_eval do
    def to_graphviz(gv)
      gv.node(self.graphviz_id, label: name, shape: :Mrecord)
    end
    def graphviz_id() (stage.is_a?(Hanuman::Graph)||stage.is_a?(Wukong::Universe)) ? graph_id : stage.graph_id ; end
  end

  InputSlot.class_eval do
    def gv_into_label() %Q{"#{graphviz_id}":"#{name}"}  ; end
    def to_graphviz(gv)
      super.tap{|node| node.receive!(inslots: [name] )}
    end
  end

  OutputSlot.class_eval do
    def gv_from_label() %Q{"#{graphviz_id}":"_#{name}"} ; end
    def to_graphviz(gv)
      super.tap{|node| node.receive!(outslots: [name] )}
    end
  end

end
