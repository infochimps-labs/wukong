require File.expand_path('../spec_helper', File.dirname(__FILE__))
require 'wukong'

describe 'wukong', :helpers => true do
  subject{ described_class.new(:example) }

  describe Wukong::Flow do
    let(:test_sink){ test_array_sink }
    let(:example_flow) do
      test_sink = test_sink()
      Wukong.flow(:simple) do
        source(:iter, 1..100) | limit(7) | test_sink
      end
    end

    it 'works with a simple example' do
      example_flow.run
      test_array_sink.records.should == (1..7).to_a
    end

    context '#run' do
      let(:test_sink){ mock }
      it 'announces events and calls methods in right order' do
        test_sink = test_sink()
        test_sink.should_receive(:tell).with(:beg_stream).ordered
        test_sink.should_receive(:call).exactly(7).times.ordered
        test_sink.should_receive(:finally).once.ordered
        test_sink.should_receive(:tell).with(:end_stream).ordered
        example_flow.run
      end
    end

    context '#make' do
      it 'creates named class' do
        subject.make(:source, :iter, []).should be_a(Wukong::Source::Iter)
      end
    end

    context '#stdin' do
      its(:stdin){ should be_a(Wukong::Source::Iter) }
    end
    context '#stdout' do
      its(:stdout){ should be_a(Wukong::Sink::Stdout) }
    end
    context '#stderr' do
      its(:stderr){ should be_a(Wukong::Sink::Stderr) }
    end

  end

  describe Wukong do
    context '.streamer' do
      subject{ Wukong.streamer('from_meth'){ def call(rec) rec.reverse ; end ; def bob() 1 ; end } }
      it 'raises an error if the handle is not a valid identifier' do
        ->{ Wukong.streamer('1love')     }.should raise_error(ArgumentError, /no funny/)
        ->{ Wukong.streamer('this/that') }.should raise_error(ArgumentError, /no funny/)
        ->{ Wukong.streamer('This::That') }.should raise_error(ArgumentError, /no funny/)
      end

      it{ should < Wukong::Streamer::Base }
      it{ should be_method_defined(:call) }
      it{ should be_method_defined(:bob) }

      it 'defines a constant in Wukong::Streamer' do
        subject.to_s.should == 'Wukong::Streamer::FromMeth'
        Wukong::Streamer.should be_const_defined(:FromMeth)
      end
      it 'raises if already defined' do
        subject
        ->{ Wukong.streamer('from_meth') }.should raise_error(ArgumentError, /already defined/i)
      end

      it 'works as expected' do
        subject.new.call("hi mom").should == "mom ih"
        subject.new.bob.should == 1
      end

      after{ Wukong::Streamer.send(:remove_const, :FromMeth) if Wukong::Streamer.const_defined?(:FromMeth) }
    end
  end

end
