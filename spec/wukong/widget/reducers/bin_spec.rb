require 'spec_helper'

describe "Reducers" do
  describe :bin do
    include_context "reducers"
    it_behaves_like 'a processor', :named => :bin

    let(:bins) {
      [
       ['0.0',    '2.000',  '9.000'],
       ['2.000',  '4.000',  '9.000'],
       ['4.000',  '6.000',  '8.000'],
       ['6.000',  '8.000', '11.000'],
       ['8.000', '10.000', '13.000']
      ]
    }

    it "raises an error when called with a non-positive-definite number of bins" do
      lambda { processor(num_bins: -1) }.should raise_error(Wukong::Error)
    end

    it "raises an error when called with a a minimum that's less than or equal to the maximum" do
      lambda { processor(min: 10, max: 0) }.should raise_error(Wukong::Error)
    end

    it "will bin 50 numbers into 7 bins (uses the square root)" do
      processor.given(*nums).should emit(7).records
    end

    it "will bin 50 numbers into 5 bins if asked" do
      processor(num_bins: 10).given(*nums).should emit(10).records
    end

    it "counts correctly in each bin" do
      processor(num_bins: 5).given(*nums).should emit_tsv(*bins)
    end

    it "can express counts logarithmically" do
      row = processor(num_bins: 5, log_counts: true).given(*nums).tsv_output.first
      row.size.should == 3
      row[2].to_f.should be_within(0.1).of(2.197)
    end

    it "can add a normalized frequency" do
      row = processor(num_bins: 5, normalize: true).given(*nums).tsv_output.first
      row.size.should == 4
      row[3].to_f.should be_within(0.1).of(0.18)
    end

    it "can add a normalized frequency and express counts logarithmically" do
      row = processor(num_bins: 5, normalize: true, log_counts: true).given(*nums).tsv_output.first
      row.size.should == 4
      row[2].to_f.should be_within(0.1).of(2.197)
      row[3].to_f.should be_within(0.1).of(-1.715)
    end

    it "can bin on the fly given min, max, and num_bins options" do
      output = processor(min: -30, max: 30, num_bins: 3) do |proc|
        # we can bin on the fly
        proc.values.should_not_receive(:<<)
        proc.should_not_receive(:bin!) 
      end.given(*nums).tsv_output

      output.size.should == 3
      output.first[0].to_f.should be_within(0.1).of(-30)
      output.last[1].to_f.should be_within(0.1).of(30)
    end

    it "can bin on the fly given fixed bin edges" do
      output = processor(edges: [0,1,5,10]) do |proc|
        # we can bin on the fly
        proc.values.should_not_receive(:<<)
        proc.should_not_receive(:bin!)
      end.given(*nums).tsv_output
      output.size.should == 3
      output[0][0].to_f.should be_within(0.1).of(0.0)
      output[0][1].to_f.should be_within(0.1).of(1.0)
      output[1][0].to_f.should be_within(0.1).of(1.0)
      output[1][1].to_f.should be_within(0.1).of(5.0)
      output[2][0].to_f.should be_within(0.1).of(5.0)
      output[2][1].to_f.should be_within(0.1).of(10.0)
    end

    it "can extract the value to bin by from an object" do
      output = processor(by: 'data.n', min: 0).given(*json).tsv_output
      output.size.should == 2
      output.first[0].to_f.should be_within(0.1).of(0.0)
      output.last[1].to_f.should be_within(0.1).of(100.0)
    end

  end
end
