require 'spec_helper'
require 'wukong'
require 'wukong/local_runner'

describe Wukong::LocalRunner, :examples_spec => true, :helpers => true do

  context 'examples' do

    # subject{
    #   Wukong.dataflow do
    #     reject{|int| int.odd? } >
    #       map{|i| i.to_s } >
    #       re(/..+/) >
    #       limit(20)
    #     puts stages
    #   end
    #
    #   Wukong::LocalRunner.new do
    #     source   :test_source, Wukong::Source::Integers.new(:max => 100)
    #     sink     :test_sink,   Wukong::Sink::Stdout.new
    #     flow     Wukong.dataflow
    #   end
    # }

    subject{
      Wukong.dataflow(:integers) do
        map{|i| i.to_s } >
          re(/..+/) >
          map(&:reverse) >
          limit(20)
      end
      runner = Wukong::LocalRunner.receive(:sinks => [test_sink] )
      runner.receive! do
        source   :test_source, Wukong::Source::Integers.new(:max => 100)
        # sinks[:test_sink] = test_sink
        flow     Wukong.dataflow(:integers)
      end
    }

    it '' do
      subject.run
    end

  end
end
