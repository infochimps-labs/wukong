require 'spec_helper'
require 'wukong'

shared_examples_for 'it can be linked from' do
  let(:mock_slot){ mock('mock stage') }
  before do
    mock_dataflow.stub(:connect).with(subject, mock_slot).and_return([subject, mock_slot])
    subject.write_attribute(:owner, mock_dataflow)
  end

  context '#>' do
    it 'asks its owner to register an edge into self from given stage' do
      mock_dataflow.should_receive(:connect).with(subject, mock_slot)
      subject.into mock_slot
    end
    it 'returns the output stage' do
      (subject > mock_slot).should == mock_slot
    end
  end

  context '#into' do
    it 'asks its owner to register an edge into self from given stage' do
      mock_dataflow.should_receive(:connect).with(subject, mock_slot)
      subject.into mock_slot
    end
    it 'returns the stage itself, for chaining' do
      subject.into(mock_slot).should == subject
    end
  end
end

shared_examples_for 'it can be linked into' do
  let(:mock_slot){ mock('mock stage') }
  before do
    mock_dataflow.stub(:connect).with(mock_slot, subject).and_return([mock_slot, subject])
    subject.write_attribute(:owner, mock_dataflow)
  end

  context '#<<' do
    it 'delegates to from' do
      subject.should_receive(:from).with(mock_slot)
      subject << mock_slot
    end
    it 'returns the stage itself, for chaining' do
      (subject << mock_slot).should == subject
    end
  end

  context '#from' do
    it 'asks its owner to register an edge from self into given stage' do
      mock_dataflow.should_receive(:connect).with(mock_slot, subject)
      subject.from mock_slot
    end
    it 'returns the stage itself, for chaining' do
      subject.from(mock_slot).should == subject
    end
  end
end

describe :stages, :slot_specs => true, :helpers => true do

  describe Hanuman::Stage do
    let(:mock_dataflow){ md = mock('dataflow') ; md }
    subject{ test_processor }
    let(:test_re){ /^m/ }

    it{ should respond_to(:setup)  }
    it{ should respond_to(:stop)   }
    it{ should respond_to(:notify) }
    it{ should respond_to(:report) }

    context 'edges' do

      it_behaves_like 'it can be linked from'
      it_behaves_like 'it can be linked into'
    end
  end
end
