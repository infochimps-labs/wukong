require File.expand_path('../spec_helper', File.dirname(__FILE__))
require 'wukong'

describe 'wukong', :helpers => true do
  subject{ described_class.new(:example) }

  describe Wukong::Flow::Simple do
    it 'works with a simple example' do
      test_sink = test_array_sink
      Wukong.flow(:simple) do
        source(1..100) | limit(7) | test_sink
        run
      end
      test_sink.records.should == (1..7).to_a
    end

    context '#make' do
      it 'creates named class' do
        subject.make(:source, :proxy, []).should be_a(Wukong::Source::Proxy)
      end
    end

    context '#stdin' do
      its(:stdin){ should be_a(Wukong::Source::Proxy) }
    end
    context '#stdout' do
      its(:stdout){ should be_a(Wukong::Sink::Stdout) }
    end
    context '#stderr' do
      its(:stderr){ should be_a(Wukong::Sink::Stderr) }
    end

  end


end
