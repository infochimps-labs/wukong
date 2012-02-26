require File.expand_path('../spec_helper', File.dirname(__FILE__))
require 'wukong'

describe :flows, :helpers => true do
  subject{ described_class.new(:example) }

  describe Wukong::Flow::Simple do
    it 'something' do
      test_sink = Wukong::Sink::ArrayCapture.new
      Wukong.flow(:simple) do
        # make(:streamer, :limit, 2)
        source(Wukong::Source::Demo.new).
          into(Wukong::Streamer::Limit.new(7)).
          into(test_sink)

        # test_sink.should_receive(:call).with("hi").once
        # stdout.should_receive(:call).with("world").once
        # stdout.should_receive(:call).with("yo").once
        source.run
      end
      test_sink.records.should == (1..7).to_a
    end

    context '#make' do
      it 'creates named class' do
        subject.make(:source, :stdin).should be_a(Wukong::Source::Stdin)
      end
    end

    context '#stdin' do
      its(:stdin){ should be_a(Wukong::Source::Stdin) }
    end
  end


end
