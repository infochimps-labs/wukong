require 'spec_helper'

describe "Reducers" do
  describe :moments do
    include_context "reducers"
    it_behaves_like 'a processor', :named => :moments

    it "behaves like group when not called with any arguments" do
      processor(:moments).given(*strings.sort).should emit(
        {group: 'apple',  count: 2, results: {}},
        {group: 'banana', count: 1, results: {}},
        {group: 'cookie', count: 1, results: {}}
      )
    end

    it "behaves calculates the moments of numeric fields" do
      processor(:moments, group_by: 'outer', of: 'data.n').given(*json_sorted_outer).should emit(
        {group: nil,      count: 2, results: {"data.n" => {}}},
        {group: 'apple',  count: 2, results: {"data.n"=>{:count=>2, :mean=>3.0,   :std_dev=>2.0}}},
        {group: 'banana', count: 1, results: {"data.n"=>{:count=>1, :mean=>100.0, :std_dev=>0.0}}},
        {group: 'cookie', count: 1, results: {"data.n"=>{:count=>1, :mean=>10.0,  :std_dev=>0.0}}}
      )
    end

    it "will leave off the standard deviation if desired" do
      processor(:moments, group_by: 'outer', of: 'data.n', std_dev: false).given(*json_sorted_outer).should emit(
        {group: nil,      count: 2, results: {"data.n" => {}}},
        {group: 'apple',  count: 2, results: {"data.n"=>{:count=>2, :mean=>3.0   }}},
        {group: 'banana', count: 1, results: {"data.n"=>{:count=>1, :mean=>100.0 }}},
        {group: 'cookie', count: 1, results: {"data.n"=>{:count=>1, :mean=>10.0  }}}
      )
    end

  end
end

