module Hanuman

  class Graph
    def to_graphviz(gv=nil, options={})
      p [self, gv, options]
      gv ||= Hanuman::GraphvizBuilder.new(name)
      gv.configurate do |gv|
        gv.orient :TB
        gv.engine :dot
        gv.node(name)
        gv.cluster(name) do |gv_cl|
          stages.to_a.each do |stage|
            stage.to_graphviz(gv_cl, options)
          end
          gv.edge stages.to_a.last.name, name if stages.present?
          super(gv_cl)
        end
      end
    end
  end

  class Stage
    def to_graphviz(gv, options={})
      gv.node(name) unless is_a?(Graph)
      inputs.to_a.each do |input|
        input.to_graphviz(gv, options)
        gv.edge(input.name, name)
      end
      outputs.to_a.each do |output|
        output.to_graphviz(gv, options)
        gv.edge(name, output.name)
      end
    end
  end

  class Action
    def to_graphviz(gv, options={})
      super
      gv.square << gv.node(name)
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
