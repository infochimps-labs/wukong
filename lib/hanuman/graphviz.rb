require 'gorillib/string/human'
module Hanuman

  class Stage
    class_attribute :draw_shape
    self.draw_shape = :record

    def graphviz_node(gv)
      str = [
        '{',
        '{',
        "<in>",
        input.name[0..0],
         '}',
        '|',
        name.to_s.gsub(/[_\.]+/, "\n"),  '|',
        "<out>", '.',
        '}'
      ].join
      nn = gv.node(fullname, str)
      # nn = gv.node(fullname, name.to_s.gsub(/[_\.]+/, "\n"))
      # gv.shape(draw_shape) << nn
      gv.shape(:Mrecord) << nn
      # nn.attributes << "fixedsize=true" << "width=1.0"
      nn
    end

    def to_graphviz(gv, options={})
      graphviz_node(gv) unless is_a?(Graph)
      gv.edge(input.fullname, fullname)
    end
  end

  class Action < Stage
    self.draw_shape = :square
  end

  class Graph < Stage
    self.draw_shape = :record

    def graphviz_node(gv)
      str = [
        '{',
        '{',
        "<in>",
        input.name[0..0],
        '}',
        '|',
        name.to_s.gsub(/[_\.]+/, "\n"),
        '}'
      ].join
      nn = gv.node("#{fullname}.input", str)
      # nn = gv.node(fullname, name.to_s.gsub(/[_\.]+/, "\n"))
      # gv.shape(draw_shape) << nn
      gv.shape(:Mrecord) << nn
      # nn.attributes << "fixedsize=true" << "width=1.0"
      nn
    end

    def to_graphviz(gv=nil, options={})
      gv ||= Hanuman::GraphvizBuilder.new(fullname) do |gv|
        gv.orient :TD
        gv.engine :dot
      end

      gv.configurate do |gv|
        graphviz_node(gv)
        gv.cluster(fullname) do |gv_cl|
          gv_cl.label name
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
