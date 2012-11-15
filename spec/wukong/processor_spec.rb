require 'spec_helper'

describe Wukong::Processor do

  context '#process' do
    let(:blk){ proc { puts 'X-Men' } }
    it 'yields the record when process is called with a block' do
      subject.should_receive(:yield).with('I custom-made yo suit!')
      subject.process('I custom-made yo suit!')
    end
  end
    
end

