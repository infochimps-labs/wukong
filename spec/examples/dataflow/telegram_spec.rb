require 'spec_helper'
require 'wukong'
require 'wukong/local_runner'

load Pathname.path_to(:examples, 'dataflow/telegram.rb')

describe 'Telegram Example', :examples_spec => true, :helpers => true do

  context 'Recompose processor' do
    subject{ Wukong::Widget::Recompose }
    its(:field_names){ should include(:break_length) }

    let(:words    ){
      # 0    5    1    5    2    5    3    5    4    5    5    5    6    5    7    5    8
      %w[
        If names be not correct, language is not in accordance with
        the truth of things.  If language be not in accordance with
        the truth of things, affairs cannot be carried on to success. ] }

    context '#process' do
      it 'breaks lines correctly' do
        (2..80).each do |len|
          # run the data flow into an array sink
          test_sink = Wukong::Sink::ArraySink.new
          rc = subject.new(:break_length => len, :output => test_sink )
          words.each{|word| rc.process(word) }
          rc.stop
          # start and end are correct
          test_sink.records.first.should =~ /^If/
          test_sink.records.last.should =~ /success\.$/
          # lines should be as long as possible, but not longer
          test_sink.records[0..-2].zip(test_sink.records[1..-1]) do |line, nextl|
            nextw = nextl.split[0]
            ((line.length <= len) || line !~ /\s/).should be_true
            (line.length + nextw.length + 1 > len).should be_true
          end
        end
      end

    end
  end

  it 'runs' do
    Wukong::LocalRunner.run(ExampleUniverse.dataflow(:telegram), :default)
  end

end
