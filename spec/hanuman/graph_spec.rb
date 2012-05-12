require File.expand_path('../spec_helper', File.dirname(__FILE__))

require 'gorillib/builder'
require 'hanuman/stage'
require 'hanuman/graph'

describe Hanuman::Graph, :helpers => true do

  it 'makes a tree' do
    example_graph.tree.should == {
      :name => :pie,
      :inputs => [],
      :stages => [
        {:name=>:make_pie, :inputs=>[:crust, :filling]},
        {:name=>:bake_pie, :inputs=>[:make_pie]}
      ], 
      }
  end
  
end
