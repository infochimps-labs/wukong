require 'gorillib/string/human'
module Hanuman

  class Stage
    class_attribute :draw_shape
    self.draw_shape = :record

    def to_graphviz(gv, options={})
      gv.node(self.fullname,
        :label    => name,
        :inslots  => inputs.to_a.map{|slot|  slot.name},
        :outslots => outputs.to_a.map{|slot| slot.name},
        )
      inputs.each_value do |input|
        output_name = outputs.empty? ? "_" : outputs.to_a.first.name
        gv.edge(input.fullname, fullname, output_name, input.name)
      end
    end
  end

  class Action < Stage
    self.draw_shape = :square
  end

  class Graph < Action
    self.draw_shape = :Mrecord

    def to_graphviz(gv)
      gv.graph(fullname, :label => name) do |gv2|
        gv2.node("#{self.fullname}_i", :label => '(in)', :shape => :parallelogram)
        stages.each_value{|stage| stage.to_graphviz(gv2) }
        gv2.node("#{self.fullname}", :label => '(out)', :shape => :parallelogram)
      end
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
