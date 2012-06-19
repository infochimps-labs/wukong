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
        subject     { described_class.make(owner, 'danza')             }
        it 'returns a fullname determined by its owner' do
          subject.fullname.should == 'tony.danza'
        end
      end
    end
  end
end


class Jones < Hanuman::Action
  register_action('nugs')
end

Hanu
