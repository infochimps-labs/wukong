require 'spec_helper'
require 'wukong/widget/gibberish'

describe :sources, :helpers => true do

  describe Wukong::Source::Iter do
    subject{ described_class.new(obj: (9 .. 14), owner: test_dataflow) }
    it 'iterates over a given collection' do
      subject.to_enum.to_a.should == [9, 10, 11, 12, 13, 14]
    end
    context 'dataflow method' do
      it 'simplified args' do
        test_dataflow.iter(9 .. 14).should == subject
      end
    end
  end

  describe Wukong::Source::FileSource do
    let(:example_filename){ Pathname.path_to(:data, 'text/jabberwocky.txt') }
    subject{ described_class.receive(filename: example_filename, owner: test_dataflow) }
    before{ subject.setup }
    it 'iterates over a given collection' do
      subject.to_enum.to_a[6, 4].should == ["`Twas brillig, and the slithy toves", "  Did gyre and gimble in the wabe:", "All mimsy were the borogoves,", "  And the mome raths outgrabe.",]
    end
    context 'dataflow method' do
      it 'simplified args' do
        test_dataflow.file_source(example_filename).should == subject
      end
    end
  end

  describe Wukong::Source::Integers do
    subject{ described_class.receive(qty: 10, owner: test_dataflow) }
    before{ subject.setup }

    it 'generates integers up to the given limit' do
      subject.to_enum.to_a.should == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    end
    it 'generates nothing if the initial range is void' do
      subject.qty = 0
      subject.to_enum.to_a.should == []
    end
    it 'generates one thing if the min and max are equal' do
      subject.qty = 1
      subject.to_enum.to_a.should == [0]
    end

    context 'dataflow method' do
      it 'takes simplified args' do
        test_dataflow.integers(10).should == subject
      end
    end
  end

  describe Wukong::Widget::Gibberish do
    subject{ described_class.receive(:qty => 4) }
    before{ subject.setup }

    it 'generates integers up to the given limit' do
      subject.rng = Random.new(8675309)
      subject.to_enum.to_a.should == ["loaiaeiaeo neidgfo heeume sptfmeec naet sttptlm waaaioh detov elrrltv nii ulcsnn", "set ensr poeleaa seqi tmnreoee boooral oczncgp deaia rykcoao leo rim mmibpbfii", "artrru sto quuu doo peoehrile nto esl tia gaili tuiooey lkedotp sts kaiy weeeia", "crhi tyiiae mieubmbooa teeae roi ednz taieh zaloy syhe ret kuoa deeeo xittipl mo"]
    end

  end
end
