require 'spec_helper'
require 'wukong'

describe :processors, :helpers => true, :widgets => true do
  subject{ described_class.new }
  let(:mock_dataflow){ md = mock('dataflow') ; md }

  describe Wukong::Processor do
    it_behaves_like 'it can be linked from'
    it_behaves_like 'it can be linked into'
  end

  describe Wukong::Map do
    it_behaves_like 'a processor'
    let(:sample_proc){ ->(rec){ rec.reverse } }
    subject{ described_class.new(sample_proc) }

    it 'emits whatever the proc does' do
      subject.should_receive(:emit).with("won ytineres")
      subject.process("serenity now")
    end

    it 'accepts a proc or block arg' do
      subject = sample_dataflow.map(->(rec){ rec.reverse })
      subject.should_receive(:emit).with("won ytineres")
      subject.process("serenity now")
    end

    it 'swallows a nil result' do
      sample_proc.should_receive(:call).with(mock_val).and_return(nil)
      subject.should_not_receive(:emit)
      subject.process(mock_val)
    end

    it 'registers a dataflow helper `map`' do
      st = sample_dataflow.map{|rec| rec.reverse }
      st.should be_a(described_class)
    end
  end

  describe Wukong::Foreach do
    it_behaves_like 'a processor'
    let(:sample_proc){ ->(rec){ emit rec.reverse } }
    subject{ described_class.new(sample_proc) }

    it 'calls the proc' do
      subject.should_receive(:emit).with("won ytineres")
      subject.process("serenity now")
    end

    it 'does not call emit on your behalf' do
      subject = sample_dataflow.foreach{|rec| rec.reverse }
      mock_val.stub(:reverse)
      subject.should_not_receive(:emit)
      subject.process(mock_val)
    end

    it 'accepts a proc or block arg' do
      subject = sample_dataflow.foreach{|rec| emit rec.reverse }
      subject.should_receive(:emit).with("won ytineres")
      subject.process("serenity now")
    end

    it 'registers a dataflow helper `foreach`' do
      st = sample_dataflow.foreach{|rec| rec.reverse }
      st.should be_a(described_class)
    end
  end

  describe Wukong::Flatten do
    it_behaves_like 'a processor'
    it 'emits each item in each input' do
      subject.set_output test_sink
      [ [:this, :that], [], 1..5, { :a => :b} ].each{|rec| subject.process(rec) }
      test_sink.records.should == [:this, :that, 1, 2, 3, 4, 5, [:a, :b]]
    end
    it 'registers a dataflow helper `flatten`' do
      st = sample_dataflow.flatten
      st.should be_a(described_class)
    end
  end

  describe Wukong::AsIs do
    it_behaves_like 'a processor'
    it 'emits each record' do
      subject.should_receive(:emit).with(:this)
      subject.should_receive(:emit).with(:that)
      [:this, :that].each{|rec| subject.process(rec) }
    end
    it 'registers a dataflow helper `as_is`' do
      st = sample_dataflow.as_is
      st.should be_a(described_class)
    end
  end

  describe Wukong::Null do
    it_behaves_like 'a processor'
    it 'emits each record' do
      subject.should_not_receive(:emit)
      [:this, :that].each{|rec| subject.process(rec) }
    end
    it 'registers a dataflow helper `null`' do
      st = sample_dataflow.null
      st.should be_a(described_class)
    end
  end


end
