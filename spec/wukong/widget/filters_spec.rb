require 'spec_helper'

describe "Filters" do

  context :include_all do
    it_behaves_like 'a processor', :named => :include_all
    it "should pass everything" do
      processor.given('').given(3).given('hi').given(nil).should emit('', 3, 'hi', nil)
    end
  end

  context :null do
    it_behaves_like 'a processor', :named => :null
    it "should not pass anything, ever" do
      processor.given('').given(3).given('hi').given(nil).should emit(0).records
    end
  end

  context :regexp do
    it_behaves_like 'a processor', :named => :regexp
    it "should pass everything given no 'match' argument" do
      processor.given('snap').given('crackle').given('pop').should emit('snap', 'crackle', 'pop')
    end
    it "should pass everything its 'match' argument matches" do
      processor(match: /a/).given('snap').given('crackle').given('pop').should emit('snap', 'crackle')
    end
  end

  context :not_regexp do
    it_behaves_like 'a processor', :named => :not_regexp
    it "should pass everything given no 'match' argument" do
      processor.given('snap').given('crackle').given('pop').should emit('snap', 'crackle', 'pop')
    end
    it "should pass everything its 'match' argument matches" do
      processor(match: /a/).given('snap').given('crackle').given('pop').should emit('pop')
    end
  end

  context :limit do
    it_behaves_like 'a processor', :named => :limit
    it "should pass everything given no 'max' argument" do
      processor.given('snap').given('crackle').given('pop').should emit('snap', 'crackle', 'pop')
    end
    it "should pass only as many records as its 'max' argument" do
      processor(max: 2).given('snap').given('crackle').given('pop').given('whoa').should emit('snap', 'crackle')
    end
  end

  
end
# describe :filters, :helpers => true do
#   subject{ described_class.new }

#   describe Wukong::Widget::IncludeAll do
#     it_behaves_like('a filter processor', :named => :include_all,
#       :good => [true, false, nil, 1, Math::PI, 'The French Revolution', Object.new, Class.new],
#       :bad  => [])
#   end

#   describe Wukong::Widget::ExcludeAll do
#     it_behaves_like('a filter processor', :named => :exclude_all,
#       :good => [],
#       :bad  => [true, false, nil, 1, Math::PI, 'The French Revolution', Object.new, Class.new])
#   end

#   describe Wukong::Widget::RegexpFilter do
#     subject{ described_class.new(:pattern => /^m/) }
#     it_behaves_like('a filter processor', :named => :regexp,
#       :good => ['milbarge'],
#       :bad  => ['fitzhume'] )
#   end

#   describe Wukong::Widget::NotRegexpFilter do
#     subject{ described_class.new(:pattern => /^m/) }
#     it_behaves_like('a filter processor', :named => :not_regexp,
#       :good => ['fitzhume'],
#       :bad  => ['milbarge'] )
#   end

#   describe Wukong::Widget::Select do
#     let(:raw_proc){ ->(rec){ rec =~ /^m/ } }
#     subject{ described_class.new(blk: raw_proc) }
#     it_behaves_like('a filter processor', :named => :select,
#       :good => ['milbarge'],
#       :bad  => ['fitzhume'] )
#     context 'is created' do
#       it 'with a block' do
#         subject = described_class.new{|rec| rec =~ /^m/ }
#         subject.should be_select('milbarge')
#         subject.should be_reject('fitzhume')
#       end
#       it 'with an explicit proc' do
#         subject = described_class.new( blk: ->(rec){ rec =~ /^m/ } )
#         subject.should be_select('milbarge')
#         subject.should be_reject('fitzhume')
#       end
#     end
#   end

#   describe Wukong::Widget::Reject do
#     let(:raw_proc){ ->(rec){ rec =~ /^m/ } }
#     subject{ described_class.new(blk: raw_proc) }
#     it_behaves_like('a filter processor', :named => :reject,
#       :good => ['fitzhume'],
#       :bad  => ['milbarge'] )
#     context 'is created' do
#       it 'with a block' do
#         subject = described_class.new{|rec| rec =~ /^m/ }
#         subject.should be_select('fitzhume')
#         subject.should be_reject('milbarge')
#       end
#       it 'with an explicit proc' do
#         subject = described_class.new( blk: ->(rec){ rec =~ /^m/ } )
#         subject.should be_select('fitzhume')
#         subject.should be_reject('milbarge')
#       end
#     end
#   end

#   describe Wukong::Widget::Limit do
#     subject{ described_class.new(:max_records => 3) }
#     it_behaves_like 'a processor', :named => :limit do
#       before{ mock_next_stage }

#       context 'creating' do
#         its(:count){ should == 0 }
#         its(:max_records){ should == 3 }
#       end

#       it 'rejects objects if already at the limit' do
#         subject = described_class.new(:max_records => 0)
#         next_stage.should_not_receive(:process)
#         subject.process(mock_record)
#       end

#       it 'emits objects until at the limit' do
#         subject = described_class.new(:max_records => 2); mock_next_stage(subject)
#         next_stage.should_receive(:process).with(0)
#         next_stage.should_receive(:process).with(1)
#         4.times{|n| subject.process(n) }
#       end
#     end
#   end


# end
