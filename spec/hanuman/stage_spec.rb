require 'spec_helper'
require 'hanuman'

describe :stages, :slot_specs => true, :helpers => true do

  describe Hanuman::Stage do
    
    context '#into' do
      let(:other_stage) { described_class.new }
      it 'returns the stage it connected to' do
        subject.into(other_stage) == other_stage
      end
      
      it 'adds the stage to the end of its outputs' do
        expect{ subject.into(other_stage) }.to 
        change{ subject.outputs }.from( [] ).to( [other_stage] )
      end
    end

    context '#fullname' do
      context 'without owner' do
        it 'returns its handle' do
          subject.fullname.should == subject.class.handle
        end
      end
      
      context 'with owner' do
        let(:owner) { Hanuman::Graph.receive(:name => 'tony') } 
        subject     { described_class.make(owner, 'danza')    }
        it 'returns a fullname determined by its owner' do
          subject.fullname.should == 'tony.danza'
        end
      end
    end
  end
end

Hanuman.stage(:jones) do
  def wacky() true ; end
end 
# ===
class Jones < Hanuman::Stage
  def wacky() true ; end
  register_stage
end

Hanuman::Stage.defined_stages #=> { :jones => Jones }

Hanuman.graph(:test) do
  mapper  = map(:as => :mapper) { |n| add_count(n) }
  reducer = map(:as => :reducer){ |n| stack(n)     }
  nugs > mapper > reducer > stdout
  register_graph         # All graphs have #test method that returns this graph now
end

Hanuman.graph(:test).edges #=> [[test.nugs, test.mapper], [test.mapper, test.reducer], [test.reducer, test.stdout]]

Hanuman.graph(:other) do
  stdin > test
end

Hanuman.graph(:other).edges #=> [[other.stdin, test.nugs], [test.nugs, test.mapper], [test.mapper, test.reducer], [test.reducer, test.stdout]]

def self.graph(graph_name, &blk)
  g = Graph.defined_graphs(graph_name) || Graph.make(:name => graph_name.to_sym)
  g.extend self.universe
  g.instance_eval(&blk)
  g
end
