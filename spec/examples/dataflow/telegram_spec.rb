require 'spec_helper'
require 'wukong'
require 'wukong/local_runner'

load Pathname.path_to(:examples, 'dataflow/telegram.rb')

describe 'Telegram Example', :examples_spec => true, :helpers => true do

  context 'processor Recompose' do
    subject{ Wukong::Widget::Recompose }
    let(:recomposer_30){ subject.new( :break_length => 30 )}
    let(:recomposer_34){ subject.new( :break_length => 34 )}

    its(:field_names){ should include(:break_length) }
    context '#processor' do
      let(:words    ){
        # 0    5    1    5    2    5    3    5    4    5    5    5    6    5    7    5    8
        %w[
          If names be not correct, language is not in accordance with
          the truth of things.  If language be not in accordance with
          the truth of things, affairs cannot be carried on to success. ] }
      let(:word_of_34_chars){ 'supercalifragilisticexpialidocious' }

      context 'very long words' do
        it 'emitted on a line of their own' do
          recomposer_34.should_receive(:emit).with(word_of_34_chars)
          recomposer_34.process(word_of_34_chars)
        end
        it 'clears a prior buffer first' do
          recomposer_34.should_receive(:emit).with('If names be not correct,')
          recomposer_34.should_receive(:emit).with(word_of_34_chars)
          words[0..4].each{|word| recomposer_34.process(word) }
          recomposer_34.process(word_of_34_chars)
        end
      end

      it 'does not violate the constraints' do
        (2..80).each do |len|
          test_sink = Wukong::Sink::ArraySink.new
          rc = subject.new(:break_length => len, :output => test_sink )
          words.each{|word| rc.process(word) }
          rc.stop
          test_sink.records[0..-2].zip(test_sink.records[1..-1]).all?{|line, nextl|
            nextw = nextl.split[0]
            one_word_or_in_bounds = ((line.length <= len) || line !~ /\s/)
            next_line_would_break = (line.length + nextw.length + 1 > len)
            one_word_or_in_bounds && next_line_would_break
          }.should == true
        end
      end

      context 'text' do
        it 'is correct on width 30' do
          recomposer_30.should_receive(:emit).with("If names be not correct,")
          recomposer_30.should_receive(:emit).with("language is not in accordance")
          recomposer_30.should_receive(:emit).with("with the truth of things. If")
          recomposer_30.should_receive(:emit).with("language be not in accordance")
          recomposer_30.should_receive(:emit).with("with the truth of things,")
          recomposer_30.should_receive(:emit).with("affairs cannot be carried on")
          recomposer_30.should_receive(:emit).with("to success.")
          words.each{|word| recomposer_30.process(word) }
          recomposer_30.stop
        end
      end
    end
  end

  it 'runs' do
    Wukong::LocalRunner.new do
      output_filename = Pathname.path_to(:tmp, 'output/dataflow/telegram/names.txt')
      output_filename.dirname.mkpath

      source   :test_source, Wukong::Source::FileSource.new(Pathname.path_to(:data, 'rectification_of_names.txt'))
      sink     :default_sink,   Wukong::Sink::FileSink.new(output_filename)
      flow     TelegramUniverse.dataflow(:telegram)
    end.run
  end

end
