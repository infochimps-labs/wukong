require 'spec_helper'

describe "Operators" do

  describe :map do
    it_behaves_like 'a processor', :named => :map
    it "performs an action on each input record" do
      processor(:map, action: ->(input_record) { input_record.upcase }).given('snap', 'crackle', 'pop').should emit('SNAP', 'CRACKLE', 'POP')
    end

    it "can simultaneously filter out records" do
      processor(:map, compact: true, action: ->(input_record) { input_record + 1 if input_record > 0 }).given(2, -4, 6).should emit(3, 7)
    end
  end

  describe :flatten do
    it_behaves_like 'a processor', :named => :flatten

    it "yields each input record or its contents" do
      processor(:flatten).given('foo', ['bar', 'baz'], 'bing').should emit('foo', 'bar', 'baz', 'bing')
    end
    
  end
  
end
