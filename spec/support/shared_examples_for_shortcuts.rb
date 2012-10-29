shared_examples_for Hanuman::Shortcuts do

  after(:each) { subject.registry.clear! }
  
  context '.registry' do
    it 'returns the registry'  do
      subject.registry.should == Hanuman::GlobalRegistry
    end
  end
  
  context '.add_shortcut_method_for' do
    let(:shortcut){ :banshee }
    it 'add shortcut methods for creating builders' do
      expect{ subject.add_shortcut_method_for(shortcut, Hanuman::StageBuilder) }.to change{ subject.respond_to? shortcut }.from(false).to(true)
    end
  end

  context '.builder_shortcut' do
    context 'with an existing definition' do
      let(:existing_definition){ Hanuman::StageBuilder.receive(label: :sunfire) }

      it 'returns the existing definition from the registry' do
        subject.registry.create(:sunfire, existing_definition)
        subject.registry.should_receive(:retrieve).with(:sunfire).and_return(existing_definition)
        subject.builder_shortcut(Hanuman::StageBuilder, :sunfire)         
      end
    end
    
    context 'with a nonexisting definition' do
      let(:mock_builder_type){ double :builder_type }
      let(:mock_builder)     { double :builder      }
      let(:block_arg)        { ->(){ def absorb() 'radiation' ; end } }

      it 'creates a new definition using the supplied builder_type' do
        mock_builder_type.should_receive(:receive).with(label: :sunfire).and_return mock_builder
        mock_builder.should_receive(:define).with(&block_arg)
        subject.builder_shortcut(mock_builder_type, :sunfire, &block_arg)
      end
    end

    context 'graph builder decoration' do
      it 'decorates the builder with registry methods if the builder is a GraphBuilder' do
        Hanuman::GlobalRegistry.should_receive(:decorate_with_registry).with an_instance_of(Hanuman::GraphBuilder)
        subject.builder_shortcut(Hanuman::GraphBuilder, :sunfire)
      end
    end
  end
  
end
