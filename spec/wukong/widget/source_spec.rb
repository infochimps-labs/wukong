require 'spec_helper'
require 'wukong/widget/gibberish'

describe :sources, :helpers => true do
  describe Wukong::Source::Integers do
    subject{ described_class.receive(:size => 10) }
    before{ subject.setup }

    it 'generates integers up to the given limit' do
      subject.to_enum.to_a.should == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    end
    it 'generates nothing if the initial range is void' do
      subject.size = 0
      subject.to_enum.to_a.should == []
    end
    it 'generates one thing if the min and max are equal' do
      subject.size = 1
      subject.to_enum.to_a.should == [0]
    end
  end

  describe Wukong::Widget::Gibberish do
    subject{ described_class.receive(:size => 3) }
    before{ subject.setup }

    it 'generates integers up to the given limit' do
      subject.rng = Random.new(8675309)
      subject.to_enum.to_a.should == ["loaiaeiaeo neidgfo heeume sptfmeec naet sttptlm waaaioh detov elrrltv nii ulcsnn", "set ensr poeleaa seqi tmnreoee boooral oczncgp deaia rykcoao leo rim mmibpbfii", "artrru sto quuu doo peoehrile nto esl tia gaili tuiooey lkedotp sts kaiy weeeia", "crhi tyiiae mieubmbooa teeae roi ednz taieh zaloy syhe ret kuoa deeeo xittipl mo"]
    end

  end
end
