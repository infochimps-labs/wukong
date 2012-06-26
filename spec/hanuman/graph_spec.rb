require 'spec_helper'
require 'hanuman'

class Foo < Hanuman::Stage ; register_stage ; end
class Bar < Hanuman::Stage ; register_stage ; end
class Baz < Hanuman::Stage ; register_stage ; end

describe Hanuman::Graph, :helpers => true do
  subject{ Hanuman::Universe.graph(self.class.description) }

  context 'simple' do
    it 'constructs a simple graph' do
      subject.receive!{ foo > bar }
      puts Hanuman::Universe.graph(:simple).object_id
      subject.stages.keys.should == ['simple.foo', 'simple.bar']
      subject.edges.should       == [['simple.foo', 'simple.bar']]
    end
  end

  context 'linked' do
    it 'constructs a linked graph' do
      puts Hanuman::Universe.graph(:simple).object_id
      subject.receive!{ baz > simple }
      subject.stages.keys.should == ['linked.baz', 'linked.simple']
      subject.edges.should       == [['linked.baz', 'linked.simple']]
    end
  end

  # it 'makes a tree' do
  #   example_graph.tree.should == {
  #     :name => :pie,
  #     :inputs => [:bake_pie],
  #     :stages => [
  #       {:name=>:make_pie, :inputs=>[:crust, :filling]},
  #       {:name=>:bake_pie, :inputs=>[:make_pie]}
  #     ],
  #     }
  # end

end
