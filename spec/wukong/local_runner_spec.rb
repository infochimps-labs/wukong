require 'spec_helper'
require 'wukong'
require 'wukong/local_runner'

describe Wukong::LocalRunner, :examples_spec => true, :helpers => true do

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
end
