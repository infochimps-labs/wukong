require 'spec_helper'
require 'wukong'

describe Wukong::Dataflow, :helpers => true do
  subject{ described_class.new }
  let(:test_re){  /^f/ }

  context 'examples' do

    subject{
      test_sink = test_sink()
      Wukong.dataflow(:integers) do
        input   :default, Wukong::Source::Integers.new(:size => 100)
        output  :default, test_sink

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
    it 'given a regexp, evaluates it on each record, selecting if it matches' do
      result = subject.select(test_re)
      result.should      be_a(Wukong::Widget::RegexpFilter)
      result.pattern.should   be(test_re)
      result.should      be_select("fitzhume")
      result.should_not  be_select("milbarge")
    end

    it 'given a proc, evaluates it on each record, selecting if true' do
      result = subject.select{|rec| rec.odd? }
      result.should      be_a(Wukong::Widget::ProcFilter)
      result.should      be_select(3)
      result.should_not  be_select(2)
    end

    it 'given a block arg, evaluates the block on each record, selecting if true' do
      result = subject.select( ->(rec){ rec.odd? } )
      result.should      be_a(Wukong::Widget::ProcFilter)
      result.should      be_select(3)
      result.should_not  be_select(2)
    end

    it 'adds a stage to the dataflow' do
      subject.should_receive(:set_stage).and_return(mock_val)
      subject.select(/^h/).should equal(mock_val)
    end
  end

  context '#reject' do
    it 'given a regexp, rejects items matching that regexp' do
      result = subject.reject(test_re)
      result.should      be_a(Wukong::Widget::RegexpRejecter)
      result.pattern.should be(test_re)
      result.should_not  be_select("fitzhume")
      result.should      be_select("milbarge")
    end

    it 'given a proc, evaluates the proc on each record, rejecting if true' do
      result = subject.reject{|rec| rec.odd? }
      result.should      be_a(Wukong::Widget::ProcRejecter)
      result.should_not  be_select(3)
      result.should      be_select(2)
    end

    it 'given a block arg, evaluates the block on each record, rejecting if true' do
      result = subject.reject( ->(rec){ rec.odd? } )
      result.should      be_a(Wukong::Widget::ProcRejecter)
      result.should_not  be_select(3)
      result.should      be_select(2)
    end

    it 'adds a stage to the dataflow' do
      subject.should_receive(:set_stage).and_return(mock_val)
      subject.select(/^h/).should equal(mock_val)
    end
  end
end
