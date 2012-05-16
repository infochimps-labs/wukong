require 'spec_helper'
require 'wukong'

describe :stages, :helpers => true do

  describe Hanuman::Stage do
    subject{ test_processor }
    let(:test_re){ /^m/ }

    it{ should respond_to(:setup) }
    it{ should respond_to(:stop) }
    it{ should respond_to(:notify) }
    it{ should respond_to(:report) }

    context '#>' do
      it "sets the given stage as the output; returns the new stage" do
        subject.should_receive(:output).with(mock_processor).and_return(mock_val)
        (subject > mock_processor).should equal(mock_processor)
      end
    end

    context '#<<' do
      it "sets this as the other stage's output; returns the current stage" do
        mock_processor.should_receive(:output).with(subject).and_return(mock_val)
        (subject << mock_processor).should equal(subject)
      end
    end

  end

end
