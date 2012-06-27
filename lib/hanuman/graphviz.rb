module Hanuman

  Stage.class_eval do
    class_attribute :draw_shape
    self.draw_shape = :record

    def to_graphviz(gv)
      gv.node(self.fullname,
        :label    => name,
        :shape    => draw_shape)
      # inputs.to_a.each do |input|
      #   gv.edge(input.fullname, self.fullname)
      # end
    end
  end

  # Slottable.module_eval do
  #   def to_graphviz(gv, draw_edges=true)
  #     gv.node(self.fullname,
  #       :label    => name,
  #       :inslots  => inslots.to_a.map{|slot|  slot.name},
  #       :outslots => outslots.to_a.map{|slot| slot.name},
  #       :shape    => draw_shape
  #       )
  #     # inslots.to_a.each do |inslot|
  #     #   next unless inslot.input?
  #     #   gv.edge(inslot.input.fullname, inslot.fullname)
  #     # end
  #   end
  # end
  #
  # InputSlot.class_eval do
  #   def fullname
  #     %Q{"#{stage.fullname}":#{name}}
  #   end
  # end
  #
  # OutputSlot.class_eval do
  #   def fullname
  #     %Q{"#{stage.fullname}":out_#{name}}
  #   end
  # end

  Resource.class_eval do
    self.draw_shape = :Mrecord
  end

  class Graph < Action
    self.draw_shape = :record
    def to_graphviz(gv)
      gv.graph(fullname, :label => name) do |gv2|
        stages.each_value{|stage| stage.to_graphviz(gv2) }
        edges.each_pair do |from, into|
          gv2.edge(from.fullname, into.fullname)
        end
      end
      super(gv)
    end
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

end
