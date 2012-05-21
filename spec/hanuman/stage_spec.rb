require 'spec_helper'
require 'wukong'

shared_examples_for 'it can be linked from' do
  let(:mock_stage){ mock('mock stage') }
  before{ mock_dataflow.stub(:connect) }

  context '#>' do
    it 'asks its owner to register an edge into self from given stage' do
      mock_dataflow.should_receive(:connect).with(subject, mock_stage)
      subject.into mock_stage
    end
    it 'returns the output stage' do
      (subject > mock_stage).should == mock_stage
    end
  end

  context '#into' do
    it 'asks its owner to register an edge into self from given stage' do
      mock_dataflow.should_receive(:connect).with(subject, mock_stage)
      subject.into mock_stage
    end
    it 'returns the stage itself, for chaining' do
      subject.into(mock_stage).should == subject
    end
  end
end

describe :stages, :helpers => true do

  describe Hanuman::Stage do
    let(:mock_dataflow){ md = mock('dataflow') ; md }
    subject{ test_processor }
    let(:test_re){ /^m/ }

    it{ should respond_to(:setup) }
    it{ should respond_to(:stop) }
    it{ should respond_to(:notify) }
    it{ should respond_to(:report) }

    context 'edges' do
      before do
        subject.write_attribute(:owner, mock_dataflow)
      end

      it_behaves_like 'it can be linked from'

      # context '#<<' do
      #   it 'delegates to from' do
      #     subject.should_receive(:from).with(mock_stage)
      #     subject << mock_stage
      #   end
      #   it 'returns the stage itself, for chaining' do
      #     (subject << mock_stage).should == subject
      #   end
      # end
      #
      # context '#from' do
      #   it 'asks its owner to register an edge from self into given stage' do
      #     mock_dataflow.should_receive(:connect).with(mock_stage, subject, nil, nil)
      #     subject.from mock_stage
      #   end
      #   it 'returns the stage itself, for chaining' do
      #     subject.from(mock_stage).should == subject
      #   end
      # end

      # it "sets the given stage as the output; returns the new stage" do
      #   subject.should_receive(:output).with(mock_processor).and_return(mock_val)
      #   (subject > mock_processor).should equal(mock_processor)
      # end
      # it "sets this as the other stage's output; returns the current stage" do
      #   mock_processor.should_receive(:output).with(subject).and_return(mock_val)
      #   (subject << mock_processor).should equal(subject)
      # end

    end

  end
end
