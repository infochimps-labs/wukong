require 'spec_helper'

describe "Filters" do

  describe :null do
    it_behaves_like 'a processor', :named => :null
    it "should not pass anything, ever" do
      processor.given('', 3, 'hi', nil).should emit(0).records
    end
  end

  describe :identity do
    it_behaves_like 'a processor', :named => :identity
    it "should pass everything, always" do
      processor.given('', 3, 'hi', nil).should emit('', 3, 'hi', nil)
    end
  end
  
  describe :regexp do
    it_behaves_like 'a processor', :named => :regexp
    it "should pass everything given no 'match' argument" do
      processor.given('snap', 'crackle', 'pop').should emit('snap', 'crackle', 'pop')
    end
    it "should pass everything its 'match' argument matches" do
      processor(match: /a/).given('snap', 'crackle', 'pop').should emit('snap', 'crackle')
    end
  end

  describe :not_regexp do
    it_behaves_like 'a processor', :named => :not_regexp
    it "should pass everything given no 'match' argument" do
      processor.given('snap', 'crackle', 'pop').should emit('snap', 'crackle', 'pop')
    end
    it "should pass everything its 'match' argument matches" do
      processor(match: /a/).given('snap', 'crackle', 'pop').should emit('pop')
    end
  end

  describe :limit do
    it_behaves_like 'a processor', :named => :limit
    it "should pass everything given no 'max' argument" do
      processor.given('snap', 'crackle', 'pop').should emit('snap', 'crackle', 'pop')
    end
    it "should pass only as many records as its 'max' argument" do
      processor(max: 2).given('snap', 'crackle', 'pop', 'whoa').should emit('snap', 'crackle')
    end
  end

  describe :sample do
    it_behaves_like 'a processor', :named => :sample
    it "should pass everything given no 'fraction' argument" do
      processor.given('snap', 'crackle', 'pop').should emit('snap', 'crackle', 'pop')
    end
    it "should pass a fraction of records matching its 'fraction' argument" do
      processor(:fraction => 0.5) { |proc| proc.should_receive(:rand).and_return(0.7, 0.1, 0.6) }.given('snap', 'crackle', 'pop').should emit('crackle')
    end
  end

end
