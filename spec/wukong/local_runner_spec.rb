require 'spec_helper'
require 'wukong'
require 'wukong/local_runner'

describe Wukong::LocalRunner do

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
    #     source   :default_source, Wukong::Source::Integers.new(:max => 100)
    #     sink     :default_sink,   Wukong::Sink::Stdout.new
    #     flow     Wukong.dataflow
    #   end
    # }

    subject{
      Wukong.dataflow do
        map{|i| i.to_s } >
          re(/..+/) >
          map(&:reverse) >
          limit(20)
        puts stages
      end

      Wukong::LocalRunner.new do
        source   :default_source, Wukong::Source::Integers.new(:max => 100)
        sink     :default_sink,   Wukong::Sink::Stdout.new
        flow     Wukong.dataflow
      end
    }

    it '' do
      subject.receive! do
        puts 'workflow', self, sources, sinks
        flow.stages.to_a.each{|st| puts st }
      end
      subject.run
    end

  end
end
