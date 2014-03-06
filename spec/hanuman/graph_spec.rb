require 'spec_helper'

describe Hanuman::Graph, :hanuman => true do

  include_context "graphs"
  
  context "#ancestors" do
    context "called without any arguments" do
      it "returns all stages with an ancestor" do
        graph.ancestors.size.should == 4
      end
    end

    context "called with a stage as the first argument" do
      it "returns the immediate ancestors of the stage" do
        graph.ancestors(graph.stages[:second]).size.should == 2
      end
    end
  end

  context "#descendents" do
    context "called without any arguments" do
      it "returns all stages with a descendent" do
        graph.descendents.size.should == 4
      end
    end

    context "called with a stage as the first argument" do
      it "returns the immediate descendents of the stage" do
        graph.descendents(graph.stages[:second]).size.should == 2
      end
    end
  end

  context "#add_stage" do
    let(:stage) { Hanuman::Stage.receive(label: :orphan) }
    it "adds the stage to the graph" do
      expect { graph.add_stage(stage) }.to change { graph.stages[:orphan] }.from(nil).to(stage)
    end
    it "doesn't create any links" do
      expect { graph.add_stage(stage) }.to_not change { graph.links }
    end
  end

  context "#add_link" do
    context "when adding a new stage" do
      let(:from) { graph.stages[:fourth]  }
      let(:into) { Hanuman::Stage.receive(label: :fifth) }
      it "adds the new stage to the graph" do
        expect { graph.add_link(:simple, from, into) }.to change { graph.stages[:fifth] }.from(nil).to(into)
      end
      it "adds the new link to the graph" do
        expect { graph.add_link(:simple, from, into) }.to change { graph.links.size }.by(1)
      end
    end
    context "when adding an existing link" do
      let(:from) { graph.stages[:third_a] }
      let(:into) { graph.stages[:fourth]  }
      it "duplicates the link in the graph" do
        expect { graph.add_link(:simple, from, into) }.to change { graph.links.size }.by(1)
      end
    end
    context "when making a cycle" do
      let(:from) { graph.stages[:fourth] }
      let(:into) { graph.stages[:first_a]  }
      it "adds the link in the graph" do
        expect { graph.add_link(:simple, from, into) }.to change { graph.links.size }.by(1)
      end
    end
    context "when linking a stage to itself" do
      let(:from) { tree.stages[:fourth] }
      let(:into) { tree.stages[:fourth]  }
      it "adds the link in the graph" do
        expect { graph.add_link(:simple, from, into) }.to change { graph.links.size }.by(1)
      end
    end
  end
  
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
