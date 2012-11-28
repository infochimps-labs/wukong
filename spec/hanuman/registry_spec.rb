require 'spec_helper'

describe Hanuman::Registry, :hanuman => true do

  before(:each) do
    @orig_reg = Hanuman.registry.show
    Hanuman.registry.clear!
  end

  after(:each) do
    Hanuman.registry.clear!
    Hanuman.registry.merge!(@orig_reg)
  end
  
  let(:definition){ { :universe => 'Marvel' }                 }
  let(:builder)   { Hanuman::StageBuilder.receive(definition) }
  
  context '#create' do
    context 'non-existing entry' do
      it 'creates a new entry for supplied definition' do
        subject.create(:storm, builder).should be true
        subject.should be_registered(:storm)
        subject.retrieve(:storm).should == builder
      end
    end

    context 'existing' do
      it 'does not create a new entry' do
        subject.create(:storm, builder)
        subject.create(:storm, builder).should be false
      end
    end
  end

  context '#update' do
    context 'non-existing entry' do
      it 'does not update the entry' do
        subject.update(:rogue, definition).should be false
        subject.should_not be_registered(:rogue)
      end
    end

    context 'existing' do
      let(:new_definition){ { :universe => 'alternate' } }
      
      it 'updates the entry' do
        subject.create(:rogue, builder)
        subject.update(:rogue, new_definition).should be true
        subject.retrieve(:rogue).serialize.should include(new_definition)
      end
    end    
  end

  context '#create_or_update' do
    context 'non-existing entry' do
      it 'creates the entry' do
        subject.should_not be_registered(:cyclops)
        subject.create_or_update(:cyclops, definition).should be true
        subject.retrieve(:cyclops).should == definition
      end
    end

    context 'existing' do
      let(:new_definition){ { :universe => 'alternate' } }

      it 'updates the entry' do
        subject.create(:cyclops, builder)
        subject.create_or_update(:cyclops, new_definition).should be true
        subject.retrieve(:cyclops).serialize.should include(new_definition)
      end
    end
  end
  
  context '#decorate_with_registry' do
    let(:graph_builder){ Hanuman::GraphBuilder.receive(label: :beastman) }
    let(:definition)   { Hanuman::StageBuilder.receive(label: :mystique) }
    
    before(:each) do
      subject.create(:mystique, definition)
      subject.decorate_with_registry(graph_builder)            
    end

    it 'decorates a builder with the registry entries as methods' do
      graph_builder.should respond_to(:mystique)
    end

    it 'decorates using singleton method definitions' do
      graph_builder.dup.should_not respond_to(:mystique)
    end
    
    it 'returns an instance of Hanuman::StageBuilder for chaining' do
      graph_builder.send(:mystique).should be_instance_of(Hanuman::StageBuilder)
    end
    
    it 'adds the instance of Hanuman::StageBuilder to its :stages attribute when used' do
      graph_builder.stages.should_not include(:mystique)
      graph_builder.send(:mystique)
      graph_builder.stages.should include(:mystique)
    end

    it 'retrieves the Hanuman::StageBuilder from the registry' do
      Hanuman.registry.should_receive(:retrieve).with(:mystique).and_return(definition)
      graph_builder.send(:mystique)
    end

    it 'saves updated definitions in its :stages attribute' do
      graph_builder.send(:mystique, for_class: String)
      graph_builder.stages[:mystique].for_class.should == String
    end
    
    it 'allows for relabelling of Hanuman::StageBuilders' do
      graph_builder.send(:mystique, label: :colossus)
      graph_builder.stages.should include(:colossus)
      graph_builder.stages.should_not include(:mystique)
    end
  end
  
  context '#show' do
    it 'shows what is currently registered' do
      subject.show.should be_a(Hash)
    end
  end  
end
