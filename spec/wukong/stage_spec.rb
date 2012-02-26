require File.expand_path('../spec_helper', File.dirname(__FILE__))
require 'wukong'

describe :stages, :helpers => true do

  describe Wukong::Stage::Base do
    subject{ test_streamer }
    let(:test_re){ /^h/ }

    context '#finally' do
      it 'calls #finally on the next stage' do
        test_streamer.into(test_filter)
        test_filter.should_receive(:finally)
        test_streamer.finally
      end
    end

    it "aliases 'into' as '|'" do
      subject.should_receive(:into).with(mock_streamer)
      subject | mock_streamer
    end
    it "aliases 'into' as '>'" do
      subject.should_receive(:into).with(mock_streamer)
      subject > mock_streamer
    end

    context '#select' do
      it 'creates a RegexpFilter given a regexp' do
        subject.select(test_re)
        subject.next_stage.should      be_a(Wukong::Filter::RegexpFilter)
        subject.next_stage.re.should   be(test_re)
        subject.next_stage.should      be_accept("hello")
        subject.next_stage.should_not  be_accept("your mom")
      end

      it 'creates a ProcFilter given a proc' do
        test_proc = ->(rec){ rec.odd? }
        subject.select(test_proc)
        subject.next_stage.should      be_a(Wukong::Filter::ProcFilter)
        subject.next_stage.proc.should be(test_proc)
        subject.next_stage.should      be_accept(3)
        subject.next_stage.should_not  be_accept(2)
      end

      it 'creates a ProcFilter given a proc' do
        subject.select{|rec| rec.odd? }
        subject.next_stage.should      be_a(Wukong::Filter::ProcFilter)
        subject.next_stage.should      be_accept(3)
        subject.next_stage.should_not  be_accept(2)
      end
    end

    context '#reject' do
      it 'creates a RegexpFilter given a regexp' do
        subject.reject(test_re)
        subject.next_stage.should      be_a(Wukong::Filter::RegexpFilter)
        subject.next_stage.re.should   be(test_re)
        subject.next_stage.should_not  be_accept("hello")
        subject.next_stage.should      be_accept("your mom")
      end

      it 'creates a ProcFilter given a proc' do
        test_proc = ->(rec){ rec.odd? }
        subject.reject(test_proc)
        subject.next_stage.should      be_a(Wukong::Filter::ProcFilter)
        subject.next_stage.proc.should be(test_proc)
        subject.next_stage.should_not  be_accept(3)
        subject.next_stage.should      be_accept(2)
      end

      it 'creates a ProcFilter given a proc' do
        subject.reject{|rec| rec.odd? }
        subject.next_stage.should      be_a(Wukong::Filter::ProcFilter)
        subject.next_stage.should_not  be_accept(3)
        subject.next_stage.should      be_accept(2)
      end
    end

  end

end
