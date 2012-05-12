require File.expand_path('../spec_helper', File.dirname(__FILE__))
require 'wukong'

describe :filters, :helpers => true do

  describe Wukong::Filter::ProcFilter do
    let(:test_proc){ ->(rec){ rec =~ /^h/ } }
    subject{ described_class.new(test_proc) }

    it 'passes records according to the truthiness the block returns' do
      subject.accept?("howdy" ).should be_true
      subject.accept?("hello" ).should be_true
      subject.accept?("byebye").should_not be_true
    end
  end

end
