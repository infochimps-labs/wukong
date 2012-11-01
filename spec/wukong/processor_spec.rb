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

describe 'widgets' do
  before(:each){ load 'wukong/widget/processors.rb' }
  
  context Wukong::Processor::Null do
    
    it 'is registered' do
      Wukong.registry.should be_registered(:null)
    end
    
    context '#process' do
      it 'returns nothing when process is called' do
        subject.process('Nothing moves the Blob!').should be_nil
      end
    end
  end

  # context Wukong::Processor::Foreach do

  #   it 'is registered' do
  #     Hanuman::GlobalRegistry.should be_registered(:foreach)
  #   end
    
  #   context '#process' do
  #     it 'calls its action method when process is called' do
  #       subject.should_receive(:perform_action).with('To Me, My X-men')
  #       subject.process('To Me, My X-men')
  #     end
  #   end
  # end
  
  context Wukong::Processor::Map do
    
    it 'is registered' do
      Hanuman::GlobalRegistry.should be_registered(:map)
    end
    
    context '#process' do
      it 'calls its action method and emits the result when process is called' do
        subject.should_receive(:perform_action).with("I'm the best there is at what I do").and_return("But what I do isn't very nice")
        subject.should_receive(:emit).with("But what I do isn't very nice")
        subject.process("I'm the best there is at what I do")
      end
    end
  end
  
  context Wukong::Processor::Flatten do

    it 'is registered' do
      Hanuman::GlobalRegistry.should be_registered(:map)
    end
    
    context '#process' do
      context 'enumerable record' do
        it 'emits each record separately, in order' do
          subject.should_receive(:emit).with('Cable').ordered
          subject.should_receive(:emit).with('Sabretooth').ordered
          subject.should_receive(:emit).with('Bishop').ordered      
          subject.process(%w[Cable Sabretooth Bishop])
        end
      end
      
      context 'single record' do
        it 'emits the record singly' do
          subject.should_receive(:emit).with('Archangel')
          subject.process('Archangel')
        end
      end
    end
  end
end
