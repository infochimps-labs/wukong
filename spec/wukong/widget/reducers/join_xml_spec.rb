require 'spec_helper'

describe "Reducers" do
  describe :join_xml do
    include_context "reducers"
    it_behaves_like 'a processor', :named => :join_xml

    it "joins XML spread out over multiple lines" do
      processor(:join_xml).given('<xml>first line', 'second line', 'third line</xml>').should emit("<xml>first line\nsecond line\nthird line</xml>")
    end
    
    it "joins XML one-per-line" do
      processor(:join_xml).given('<xml>first line</xml>', '<xml>second line</xml>', '<xml>third line</xml>').should emit('<xml>first line</xml>', '<xml>second line</xml>', '<xml>third line</xml>')
    end

    it "joins XML split in the middle of a line" do
      processor(:join_xml).given('<xml>first line', 'second</xml><xml> line', 'third line</xml>').should emit("<xml>first line\nsecond</xml>", "<xml> line\nthird line</xml>")
    end

    it "joins XML with a custom tag" do
      processor(:join_xml, root: 'foobar').given('<foobar>first line', 'second line', 'third line</foobar>').should emit("<foobar>first line\nsecond line\nthird line</foobar>")
    end
    
  end
end
