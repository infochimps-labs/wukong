require File.expand_path('../../spec_helper', File.dirname(__FILE__))
require 'wukong'

describe 'wukong', :helpers => true do

  # describe Wukong::Widget::Stringifier do
  #   it 'is not registered as anything' do
  #     Wukong.should_not be_streamer_exists( Wukong::Widget::Stringifier)
  #     Wukong.should_not be_formatter_exists(Wukong::Widget::Stringifier)
  #   end
  # end

  describe 'json' do
    let(:json_data  ){ {'abc' => 'def'} }
    let(:json_string){ '{"abc":"def"}'  }

    describe Wukong::Widget::FromJson do
      it 'encodes' do
        subject.should_receive(:emit).with(json_data)
        subject.process(json_string)
      end
    end

    describe Wukong::Widget::ToJson do
      it 'encodes' do
        subject.should_receive(:emit).with(json_string)
        subject.process(json_data)
      end
    end
  end

  describe 'tsv' do
    let(:tsv_data  ){ ['abc', 'def'] }
    let(:tsv_string){ "abc\tdef"     }

    describe Wukong::Widget::FromTsv do
      it 'encodes' do
        subject.should_receive(:emit).with(tsv_data)
        subject.process(tsv_string)
      end
    end

    describe Wukong::Widget::ToTsv do
      it 'encodes' do
        subject.should_receive(:emit).with(tsv_string)
        subject.process(tsv_data)
      end
    end
  end

end
