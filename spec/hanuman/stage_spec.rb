require 'spec_helper'

describe Hanuman::Stage, :hanuman => true do

  before{ Hanuman.registry.clear! }
  
  context 'a class inheriting from Hanuman::Stage' do

    klass = Object.const_set('Gambit', Class.new(Hanuman::Stage))
    subject{ klass }

    it 'creates its own label' do
      subject.label.should == :gambit
    end
    
    it 'creates its own builder' do
      subject.builder.should be_instance_of(Hanuman::StageBuilder)
      subject.builder.for_class.should == subject
    end    
        
    it 'can register its definition' do      
      expect{ subject.register }.to change{ Hanuman.registry.retrieve(:gambit) }.from(nil).to(subject.builder)
    end

    it 'can register itself under a different label' do
      expect{ subject.register(:wolverine) }.to change{ Hanuman.registry.retrieve(:wolverine) }.from(nil)
      Hanuman.registry.retrieve(:wolverine).label.should == :wolverine
      Hanuman.registry.should_not be_registered(:gambit)
    end
  end  
end

describe Hanuman::StageBuilder, :hanuman => true do

  it_behaves_like 'a Stage::Builder'
  
  its(:namespace){ should be(Hanuman::Stage) }

  context '#define' do
    let(:test_klass){ Object.const_set('Jubilee', Class.new(subject.namespace)) }
    let(:block_arg) { ->(){ def shoot_fireworks!() ; end }                      }
    after(:each)    { Object.send(:remove_const, 'Jubilee')                     }

    context 'with a block' do
      it 'defines the class which evaluates the block' do       
        subject.for_class = test_klass
        test_klass.should_receive(:class_eval).with(&block_arg)
        subject.define(&block_arg)
      end
    end
  end

  context '#serialize' do
    it 'does not serialize its :links attribute' do
      subject.serialize.should_not include(:links)
    end
  end
end
