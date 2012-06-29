require 'spec_helper'
require 'wukong'

describe Wukong::Dataflow, :helpers => true do
  subject{ described_class.new }
  let(:test_re){  /^f/ }

  context 'examples' do

    subject{
      test_sink = test_sink()
      Wukong.dataflow(:integers) do
        set_input   :default, Wukong::Source::Integers.new(:size => 100)
        set_output  :default, test_sink

        input(:default)    >
          map{|i| i.to_s } >
          re(/..+/)        >
          map(&:reverse)   >
          limit(20)        >
          output(:default)
      end
      Wukong::LocalRunner.receive(:flow => Wukong.dataflow(:integers))
    }

    it 'runs' do
      subject.run(:default)
      subject.flow.output(:default).records.should == ["01", "11", "21", "31", "41", "51", "61", "71", "81", "91", "02", "12", "22", "32", "42", "52", "62", "72", "82", "92"]
    end

  end

  context '#select' do
    it 'evaluates block arg on each record, selecting if true' do
      result = subject.select{|rec| rec.odd? }
      result.should      be_a(Wukong::Widget::Select)
      result.should      be_select(3)
      result.should_not  be_select(2)
    end

    it 'given proc as plain arg, evaluates it on each record, selecting if true' do
      result = subject.select( ->(rec){ rec.odd? } )
      result.should      be_a(Wukong::Widget::Select)
      result.should      be_select(3)
      result.should_not  be_select(2)
    end

    it 'adds a stage to the dataflow' do
      subject.should_receive(:set_stage).with(:select_0, kind_of(Wukong::Widget::Select))
      subject.select{|rec| rec =~ /^h/ }.should be_a(Wukong::Widget::Select)
    end
  end

  context '#reject' do
    it 'evaluates block arg on each record, rejecting if true' do
      result = subject.reject{|rec| rec.odd? }
      result.should      be_a(Wukong::Widget::Reject)
      result.should_not  be_select(3)
      result.should      be_select(2)
    end

    it 'given proc as plain arg, evaluates it on each record, rejecting if true' do
      result = subject.reject( ->(rec){ rec.odd? } )
      result.should      be_a(Wukong::Widget::Reject)
      result.should_not  be_select(3)
      result.should      be_select(2)
    end

    it 'adds a stage to the dataflow' do
      subject.should_receive(:set_stage).with(:reject_0, kind_of(Wukong::Widget::Reject))
      subject.reject{|rec| rec =~ /^h/ }.should be_a(Wukong::Widget::Reject)
    end
  end
end
