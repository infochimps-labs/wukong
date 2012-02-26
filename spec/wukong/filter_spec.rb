require File.expand_path('../spec_helper', File.dirname(__FILE__))
require 'wukong'

describe :filters, :helpers => true do

  describe Wukong::Filter::ProcFilter do
    let(:test_proc){ ->(rec){ rec =~ /^h/ } }
    subject{ described_class.new(test_proc) }

    its("proc"){ should be_a(Proc) }

    it 'evaluates the proc' do
      test_proc.should_receive(:call).with(mock_record)
      subject.call(mock_record)
    end

    it 'passes records according to the truthiness the block returns' do
      subject.accept?("howdy" ).should be_true
      subject.accept?("hello" ).should be_true
      subject.accept?("byebye").should_not be_true
    end
  end

end
