require File.expand_path('../spec_helper', File.dirname(__FILE__))
require 'wukong'

describe :stages, :helpers => true do

  describe Wukong::Stage::Base do
    subject{ test_streamer }
    let(:test_re){ /^h/ }

    context '#select' do
      it 'creates a RegexpFilter given a regexp' do
        subject.select(test_re)
        subject.next_stage.should      be_a(Wukong::Filter::RegexpFilter)
        subject.next_stage.re.should   be(test_re)
        subject.next_stage.should      be_accept("hello")
        subject.next_stage.should_not  be_accept("your mom")
      end

      it 'creates a ProcFilter given a proc' do
        test_proc = lambda{|rec| rec.odd? }
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
        test_proc = lambda{|rec| rec.odd? }
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
