require 'spec_helper'

describe "Reducers" do
  describe :join_xml do
    include_context "reducers"
    it_behaves_like 'a processor', :named => :join_xml

    it "joins XML" do
      processor(:join_xml).given('<xml>first line', 'second line', 'third line</xml').should emit("<xml>first line\nsecond line\nthirdline</xml>")
    end
  end
end
