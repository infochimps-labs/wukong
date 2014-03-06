shared_context "reducers" do

  let(:strings) { %w[apple banana apple cookie] }
  let(:nums)    { %w[7 7 0 10 3 5 7 6 3 7 3 5 3 1 9 8 3 9 4 2 6 10 9 0 7 7 9 5 2 0 4 9 9 5 9 6 10 2 0 8 4 0 0 1 7 9 5 6 3 0] }
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

  let(:json_sorted_n) do
    json.map { |j| MultiJson.load(j) }.sort_by { |o| o['data']['n'].to_i }.map { |o| MultiJson.dump(o) }
  end

  let(:json_sorted_outer) do
    json.map { |j| MultiJson.load(j) }.sort_by { |o| o['outer'] || '' }.map { |o| MultiJson.dump(o) }
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

end
