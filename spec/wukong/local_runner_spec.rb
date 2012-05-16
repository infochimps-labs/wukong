require 'spec_helper'
require 'wukong'
require 'wukong/local_runner'

describe Wukong::LocalRunner do

  context 'examples' do
    subject{
      Wukong.dataflow do
        x = Wukong::Widget::ProcFilter.new{|int| int.odd? }
        stage(:odds, x)
        puts stages
        stage(:odds) > Wukong::Sink::Stdout.new
        puts stages
      end

      Wukong::LocalRunner.new do
        source   :default_source, Wukong::Source::Integers.new(:max => 10)
        sink     :default_sink,   Wukong::Sink::Stdout.new
        flow     Wukong.dataflow
      end
    }

    it '' do
      subject.receive! do
        puts 'workflow', self, sources, sinks, flow
      end
      subject.run
    end

  end
end
