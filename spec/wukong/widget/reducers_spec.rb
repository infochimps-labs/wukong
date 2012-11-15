require 'spec_helper'

describe "Reducers" do

  let(:strings) { %w[apple banana apple cookie] }
  let(:nums)    { %w[1 100 5 10] }
  let(:json)    do
    [
     '{"data":{}}',
     '{"data":{"n":1,"inner":"snap"},"outer":"apple"}',
     '{"data":{"n":100,"inner":"crackle"},"outer":"banana"}',
     '{"data":{"n":5,"inner":"crackle"},"outer":"apple"}',
     '{"data":{"n":10,"inner":"pop"},"outer":"cookie"}',
     '{"data":{}}'
     ]
  end

  let(:json_sorted) do
    json.map { |j| MultiJson.load(j) }.sort_by { |o| o['data']['n'].to_i }.map { |o| MultiJson.dump(o) }
  end
  
  let(:tsv) do
    [
     "\tb\t",
     "apple\tsnap\t1",
     "banana\tcrackle\t100",
     "apple\tcrackle\t5",
     "cookie\tpop\t10",
     "b"
     ]
  end

  let(:tsv_sorted) { tsv.sort_by { |t| t.split("\t")[2].to_i } }
  
  context :count do
    it_behaves_like 'a processor', :named => :count
    it "should emit the total count of records" do
      processor.given(*strings).should emit(4)
    end
  end

  context :sort do
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
      proc = processor(:sort, numeric: true, on: 'data.n').given(*json).should emit(*json_sorted)
    end
    it "can sort from within a TSV row" do
      proc = processor(:sort, numeric: true, on: '3').given(*tsv).should emit(*tsv_sorted)
    end
  end

  context :group do
    it_behaves_like 'a processor', :named => :group
    it "will group single values" do
      processor(:group).given(*strings.sort).should emit({group: 'apple', count: 2}, {group: 'banana', count: 1}, {group: 'cookie', count: 1})
    end
    it "can group from within a JSON hash" do
      proc = processor(:group, by: 'data.n').given(*json_sorted).should emit({group: nil, count: 2}, {group: 1, count: 1}, {group: 5, count: 1}, {group: 10, count: 1}, {group: 100, count: 1})
    end
    it "can group from within a TSV row" do
      proc = processor(:group, by: '3').given(*tsv_sorted).should emit({group: nil, count: 2}, {group: "1", count: 1}, {group: "5", count: 1}, {group: "10", count: 1}, {group: "100", count: 1})
    end
  end

  context :moments do
    it_behaves_like 'a processor', :named => :moments
  end

  context :bin do
    it_behaves_like 'a processor', :named => :bin
  end
  
end
