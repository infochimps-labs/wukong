require 'spec_helper'

require 'gorillib/builder'
require 'hanuman/stage'
require 'hanuman/slot'
require 'hanuman/graph'
require 'hanuman/chain'

require 'wukong'
require 'hanuman/graphvizzer'

require 'hanuman/graphviz_builder'
require 'hanuman/graphviz'


load Pathname.path_to(:examples, 'workflow/cherry_pie.rb')
describe 'Cherry Pie Example', :examples_spec => true, :helpers => true do

  it 'makes a png' do
    gv = Wukong.to_graphviz

    basename = Pathname.path_to(:tmp, 'cherry_pie')
    gv.save(basename, 'png')
    puts File.read("#{basename}.dot")
  end

end

describe :graphviz, :helpers => true do

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
    example_dot.to_s.should == "digraph \"three_shapes\" {\n  \"top\"                                    [ shape = square,color = red ];\n  \"mid\"                                    [ shape = triangle,color = green ];\n  \"btm\"                                    [ color = blue ];\n  \"top\"              -> \"mid\"              [ color = red ];\n  \"top\"              -> \"btm\"              [ color = blue ];\n  \"btm\"              -> \"top\";\n  \"mid\"              -> \"btm\"              [ color = green ];\n}"
  end
end
