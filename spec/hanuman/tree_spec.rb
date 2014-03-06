require 'spec_helper'

describe Hanuman::Tree do

  include_context "graphs"

  it "iterates over each stage in tree-order" do
    tree.directed_sort.should == [:first, :second, :third_b, :third_a, :fourth]
  end

  context "#root" do
    context "when called without arguments" do
      it "returns the root of the whole tree" do
        tree.root.should_not be_nil
        tree.root.label.should == :first
      end
      it "returns the root of a sigle stage tree" do
        single_stage_tree.root.should_not be_nil
        single_stage_tree.root.label.should == :first
      end
      
    end
    context "when called with a stage" do
      it "should return the root of the whole tree" do
        tree.root(tree.stages[:fourth]).should_not be_nil
        tree.root(tree.stages[:fourth]).label.should == :first
      end
    end
  end

  context "#ancestor" do
    it "returns the ancestor of a stage" do
      tree.ancestor(tree.stages[:fourth]).should_not be_nil
      tree.ancestor(tree.stages[:fourth]).label.should == :third_a
    end
    it "returns nil for the root" do
      tree.ancestor(tree.root).should be_nil
    end
  end

  context "#leaves" do
    it "returns the leaf stages of a tree" do
      tree.leaves.map(&:label).should include(:fourth, :third_b)
    end

    it "returns the root of a tree that has no other leaves" do
      single_stage_tree.leaves.map(&:label).should include(:first)
    end
    
  end

  context "#prepend" do
    let(:zeroth) { Hanuman::Stage.receive(label: :zeroth) }
    it "adds the given stage" do
      expect { tree.prepend(zeroth) }.to change { tree.stages[:zeroth] }.from(nil).to(zeroth)
    end
    it "adds a link from the new stage to the old root" do
      expect { tree.prepend(zeroth) }.to change { tree.has_link?(zeroth, tree.stages[:first]) }.from(false).to(true)
    end
    it "the root becomes the new stage" do
      expect { tree.prepend(zeroth) }.to change { tree.root.label }.from(:first).to(:zeroth)
    end
  end

  context "#append" do
    let(:fifth) { Hanuman::Stage.receive(label: :fifth) }
    it "adds a new stage for each leaf" do
      expect { tree.append(fifth) }.to change { tree.stages.size }.by(2)
    end
    it "adds a link for each of the new stages" do
      expect { tree.append(fifth) }.to change { tree.links.size }.by(2)
    end
    it "but doesn't change the number of leaves " do
      expect { tree.append(fifth) }.to_not change { tree.leaves.size }
    end
  end
  
  context "#add_link" do
    context "when adding a new stage" do
      let(:from) { tree.stages[:fourth]  }
      let(:into) { Hanuman::Stage.receive(label: :fifth) }
      it "adds the new stage to the tree" do
        expect { tree.add_link(:simple, from, into) }.to change { tree.stages[:fifth] }.from(nil).to(into)
      end
      it "adds the new link to the tree" do
        expect { tree.add_link(:simple, from, into) }.to change { tree.links.size }.by(1)
      end
    end
    context "when adding an existing link" do
      let(:from) { tree.stages[:third_a] }
      let(:into) { tree.stages[:fourth]  }
      it "doesn't duplicate the link in the tree" do
        expect { tree.add_link(:simple, from, into) }.to_not change { tree.links.size }
      end
    end
    context "when adding a link to a stage with an existing parent" do
      let(:from) { Hanuman::Stage.receive(label: :fifth) }
      let(:into) { tree.stages[:fourth]                  }
      it "raises an error" do
        expect { tree.add_link(:simple, from, into) }.to raise_error(Hanuman::Tree::MultipleRoots)
      end
    end
    context "when making a cycle" do
      let(:from) { tree.stages[:fourth] }
      let(:into) { tree.stages[:first]  }
      it "raises an error" do
        expect { tree.add_link(:simple, from, into) }.to raise_error(TSort::Cyclic)
      end
    end
    context "when linking a stage to itself" do
      let(:from) { tree.stages[:fourth] }
      let(:into) { tree.stages[:fourth]  }
      it "raises an error" do
        expect { tree.add_link(:simple, from, into) }.to raise_error(TSort::Cyclic)
      end
    end
  end
  
end
