module Hanuman

  class Stage
    class_attribute :draw_shape
    self.draw_shape = :circle

    def graphviz_node(gv)
      gv.shape(draw_shape) << gv.node(fullname, name)
    end

    def to_graphviz(gv, options={})
      graphviz_node(gv) unless is_a?(Graph)

      inputs.to_a.each do |input|
        input.to_graphviz(gv, options)
        gv.edge(input.fullname, fullname)
      end

      # outputs.to_a.each do |output|
      #   output.to_graphviz(gv, options)
      #   gv.edge(fullname, output.fullname)
      # end
    end
  end

  class Action < Stage
    self.draw_shape = :square
  end

  class Graph < Stage
    self.draw_shape = :hexagon
    def to_graphviz(gv=nil, options={})
      gv ||= Hanuman::GraphvizBuilder.new(fullname) do |gv|
        gv.orient :TB
        gv.engine :dot
      end

      gv.configurate do |gv|
        ( output || stages.to_a.last ).graphviz_node(gv)
        gv.cluster(fullname) do |gv_cl|
          stages.to_a.each do |stage|
            p [self.fullname, stage.fullname, stage, __FILE__]
            stage.to_graphviz(gv_cl, options)
          end

          # gv.edge stages.to_a.last.fullname, fullname if stages.present?
          super(gv_cl)
        end
      end
    end
  end

  # class Chain
  #   def to_graphviz(gv, options={})
  #     gv.configurate do |gv|
  #       gv.cluster(name) do
  #         stages.to_a.each do |stage|
  #           stage.to_graphviz(gv, options)
  #         end
  #       end
  #     end
  #   end
  # end

end
