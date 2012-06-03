require 'spec_helper'
require 'wukong'
require 'wukong/local_runner'

load Pathname.path_to(:examples, 'text/pig_latin.rb')

describe 'Pig Latin', :examples_spec => true, :helpers => true do

  context 'processor' do
    subject{ Wukong::Widget::PigLatinize.new }
    it 'breaks text into pig latin' do
      subject.should_receive(:emit).with("Iway indfay ethay astramipay otay ebay ethay ostmay ensualsay ofway allway ethay altedsay uredcay eatsmay.")
      subject.process("I find the pastrami to be the most sensual of all the salted cured meats.")
    end
  end

  it 'runs' do
    Wukong::LocalRunner.new do
      output_filename = Pathname.path_to(:tmp, 'output/text/pig_latin/gift_of_the_magi.txt')
      output_filename.dirname.mkpath

      source   :test_source, Wukong::Source::FileSource.new(Pathname.path_to(:data, 'text/gift_of_the_magi.txt'))
      sink     :default_sink,   Wukong::Sink::FileSink.new(output_filename)
      flow     PigLatinUniverse.dataflow(:pig_latin)
    end.run
  end

end
