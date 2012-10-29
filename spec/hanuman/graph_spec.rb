require 'spec_helper'

describe Hanuman::Graph, :hanuman => true do

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

describe Hanuman::GraphBuilder, :hanuman => true do

  it_behaves_like 'a Stage::Builder'
  
  its(:namespace){ should be(Hanuman::Graph) }
  
  context '#define' do
    let(:block_arg){ ->(){ def say() "I'm the Juggernaut!" ; end } }
    
    it 'evalutes a supplied block itself' do
      subject.label = :juggernaut
      subject.should_receive(:instance_eval).with(&block_arg)
      subject.define(&block_arg)
    end
  end
  
  context '#build' do
  end
  
  context '#serialize' do
    it 'serializes into a Hash with stages and links' do
      subject.serialize.should include(:stages, :links)
    end  
  end
end
