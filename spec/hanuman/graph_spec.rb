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
    before do
      Wukong.processor(:foo) do
        field :bones, String
      end
      Wukong.dataflow(:bar) do
        foo
      end
    end
    
    let(:graph){ Wukong.registry.retrieve(:bar) }
    it 'builds stages with specific options' do
      built = graph.build(foo: { bones: 'lala' })
      built.stages[:foo].bones.should eq('lala')
    end
  end
  
  context '#serialize' do
    it 'serializes into a Hash with stages and links' do
      subject.serialize.should include(:stages, :links)
    end  
  end
end
