require 'spec_helper'

describe Wukong::Processor do
  describe :count do
    include_context "reducers"
    it_behaves_like 'a processor', :named => :count
    it "should emit the total count of records" do
      processor.given(*strings).should emit(4)
    end
  end
end
