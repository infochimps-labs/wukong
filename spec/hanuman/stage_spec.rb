require 'spec_helper'
require 'wukong'

describe :stages, :helpers => true do

  describe Hanuman::Stage do
    subject{ test_transform }
    let(:test_re){ /^h/ }

    # context '#finally' do
    #   it 'calls #finally on the next stage' do
    #     test_transform.into(test_filter)
    #     test_filter.should_receive(:finally)
    #     test_transform.finally
    #   end
    # end

    it "aliases 'output' as '>'" do
      subject.should_receive(:output).with(mock_transform)
      subject > mock_transform
    end

  end

end
