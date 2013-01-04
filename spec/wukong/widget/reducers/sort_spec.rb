require 'spec_helper'

describe "Reducers" do
  describe :sort do
    include_context "reducers"
    it_behaves_like 'a processor', :named => :sort
    it "will use ascending order by default" do
      processor(:sort).given(*strings).should emit(*strings.sort)
    end
    it "can sort in reversed (descending) order" do
      processor(:sort, reverse: true).given(*strings).should emit(*strings.sort.reverse)
    end
    it "will use lexical order by default" do
      processor(:sort).given(*nums).should emit(*nums.sort)
    end
    it "can sort in numerical order" do
      processor(:sort, numeric: true).given(*nums).should emit(*nums.map(&:to_i).sort.map(&:to_s))
    end
    it "can sort from within a JSON hash" do
      proc = processor(:sort, numeric: true, on: 'data.n').given(*json).should emit(*json_sorted_n)
    end
    it "can sort from within a TSV row" do
      proc = processor(:sort, numeric: true, on: '3').given(*tsv).should emit(*tsv_sorted)
    end
  end
end
