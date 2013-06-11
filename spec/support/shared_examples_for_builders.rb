shared_examples_for 'a Stage::Builder' do
  before(:each){ Hanuman::GlobalRegistry.clear! }
  
  context '.receive' do
    it 'extra arguments are stored in the :args attribute' do
      subject = described_class.receive(uncanny: 'x-men')
      subject.args.should == { uncanny: 'x-men' }
    end
  end
  
  context '#define' do
    let(:test_klass){ Object.const_get('WhiteQueen') }
    
    around(:each) do |example|
      Object.const_set('WhiteQueen', Class.new(subject.namespace))
      example.run
      Object.send(:remove_const, 'WhiteQueen')
    end

    it 'returns a Hanuman::Stage class definition' do
      subject.label = :white_queen
      subject.define.superclass.should be(subject.namespace)
    end

    it 'registers the defined class' do
      subject.for_class = test_klass
      test_klass.should_receive(:register)
      subject.define
    end
    
    context 'without :for_class attribute set' do
      it 'does not create a class definition' do
        subject.for_class = test_klass
        subject.should_not_receive(:define_class)
        subject.define
      end
    end

    context 'with :for_class attribute set' do
      it 'creates a class definition' do
        subject.label = :white_queen
        subject.should_receive(:define_class).with(:white_queen).and_return(test_klass)
        subject.define
      end
    end    
  end
  
  context '#define_class' do
    around(:each) do |example| 
      subject.namespace.const_set('ProfessorX', Class.new(subject.namespace)) 
      example.run
      subject.namespace.send(:remove_const, 'ProfessorX') 
    end
    
    context 'already defined within the namespace' do
      it 'does not define the class again' do
        subject.namespace.should_not_receive(:const_set)
        subject.define_class(:professor_x)
      end
    end
    
    context 'not defined within the namespace' do
      let(:defined_class){ double :magneto, :set_builder => true }
      
      it 'defines the class' do
        subject.namespace.should_receive(:const_set).with('Magneto', an_instance_of(Class)).and_return(defined_class)
        subject.define_class(:magneto)
      end
    end
    
    context 'builder attribute' do
      let(:test_klass) { subject.namespace.const_get('ProfessorX') }
      
      it 'sets the defined class builder attribute' do
        test_klass.should_receive(:set_builder).with(subject)
        subject.define_class(:professor_x)
      end
    end
  end
  
  context '#serialize' do
    it 'serializes into a hash' do
      subject.serialize.should     include(:label) 
      subject.serialize.should_not include(:args, :for_class)
    end
  end
end
