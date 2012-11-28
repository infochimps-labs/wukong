require 'spec_helper'

describe Wukong::Processor do
  describe :group do
    include_context "reducers"
    it_behaves_like 'a processor', :named => :group
    it "will group single values" do
      processor(:group).given(*strings.sort).should emit({group: 'apple', count: 2}, {group: 'banana', count: 1}, {group: 'cookie', count: 1})
    end
    it "can group from within a JSON hash" do
      proc = processor(:group, by: 'data.n').given(*json_sorted_n).should emit({group: nil, count: 2}, {group: 1, count: 1}, {group: 5, count: 1}, {group: 10, count: 1}, {group: 100, count: 1})
    end
    it "can group from within a TSV row" do
      proc = processor(:group, by: '3').given(*tsv_sorted).should emit({group: nil, count: 2}, {group: "1", count: 1}, {group: "5", count: 1}, {group: "10", count: 1}, {group: "100", count: 1})
    end
  end
end
