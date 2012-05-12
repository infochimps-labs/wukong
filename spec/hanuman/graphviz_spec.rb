require File.expand_path('../spec_helper', File.dirname(__FILE__))

require 'gorillib/builder'
require 'hanuman/stage'
require 'hanuman/graph'
require 'hanuman/chain'
require 'hanuman/graphviz_builder'
require 'hanuman/graphviz'

describe :graphviz, :helpers => true do

  it 'makes a png' do
    gv = example_graph.to_graphviz

    p example_graph.stages

    gv.save(Gorillib.path_to(:tmp, gv.name.to_s), 'png')
    puts File.read(Gorillib.path_to(:tmp, "#{gv.name}.dot"))
  end

  it 'builder works as expected' do
    example_dot = Hanuman::GraphvizBuilder.new(:three_shapes) do  |gv|
      # many ways to access/create edges and nodes
      gv.edge "top", "mid"
      gv["top"]["btm"]
      gv.node("btm") >> "top"

      gv.square   << gv.node("top")
      gv.triangle << gv.node("mid")

      gv.red   << gv.node("top") << gv.edge("top", "mid")
      gv.green << gv.node("mid") << gv.edge("mid", "btm")
      gv.blue  << gv.node("btm") << gv.edge("top", "btm")
    end
    example_dot.to_s.should == "digraph \"three_shapes\" {\n  \"top\"                    [ shape = square,color = red ];\n  \"mid\"                    [ shape = triangle,color = green ];\n  \"btm\"                    [ color = blue         ];\n  \"top\"      -> \"mid\"      [ color = red          ];\n  \"top\"      -> \"btm\"      [ color = blue         ];\n  \"btm\"      -> \"top\";\n  \"mid\"      -> \"btm\"      [ color = green        ];\n}"
  end
end
