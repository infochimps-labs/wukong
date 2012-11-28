require 'spec_helper'

describe Wukong::Processor do
  describe :bin do
    include_context "reducers"
    it_behaves_like 'a processor', :named => :bin

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
      processor(num_bins: 5).given(*nums).should emit_json(
        {"bin" => [0.0,2.0],  "count" => 9},
        {"bin" => [2.0,4.0],  "count" => 9},
        {"bin" => [4.0,6.0],  "count" => 8},
        {"bin" => [6.0,8.0],  "count" => 11},
        {"bin" => [8.0,10.0], "count" => 13}
      )
    end

    it "can express counts logarithmically" do
      processor(num_bins: 5, logarithmic: true).given(*nums).should emit_json(
        {"bin" => [0.0,2.0],  "count" => Math.log(9)},
        {"bin" => [2.0,4.0],  "count" => Math.log(9)},
        {"bin" => [4.0,6.0],  "count" => Math.log(8)},
        {"bin" => [6.0,8.0],  "count" => Math.log(11)},
        {"bin" => [8.0,10.0], "count" => Math.log(13)}
      )
    end

    it "can normalize counts with a frequency" do
      processor(num_bins: 5, normalize: true).given(*nums).should emit_json(
        {"bin" => [0.0,2.0],  "count" => 9,  "frequency" => 0.18},
        {"bin" => [2.0,4.0],  "count" => 9,  "frequency" => 0.18},
        {"bin" => [4.0,6.0],  "count" => 8,  "frequency" => 0.16},
        {"bin" => [6.0,8.0],  "count" => 11, "frequency" => 0.22},
        {"bin" => [8.0,10.0], "count" => 13, "frequency" => 0.26}
      )
    end

    it "can normalize counts with a frequency logarithmically" do
      processor(num_bins: 5, normalize: true, logarithmic: true).given(*nums).should emit_json(
        {"bin" => [0.0,2.0],  "count" => Math.log(9),  "frequency" => Math.log(0.18)},
        {"bin" => [2.0,4.0],  "count" => Math.log(9),  "frequency" => Math.log(0.18)},
        {"bin" => [4.0,6.0],  "count" => Math.log(8),  "frequency" => Math.log(0.16)},
        {"bin" => [6.0,8.0],  "count" => Math.log(11), "frequency" => Math.log(0.22)},
        {"bin" => [8.0,10.0], "count" => Math.log(13), "frequency" => Math.log(0.26)}
      )
    end

    it "can bin on the fly given min, max, and num_bins options" do
      processor(min: -30, max: 30, num_bins: 3) do
        # we can bin on the fly
        values.should_not_receive(:<<)
        should_not_receive(:bin!) 
      end.given(*nums).should emit_json(
        {"bin" => [-30.0,-10.0],  "count" => 0 },
        {"bin" => [-10.0, 10.0],  "count" => 47},
        {"bin" => [ 10.0, 30.0],  "count" => 3 }
      )
    end

    it "can bin on the fly given fixed bin edges" do
      processor(edges: [0,1,5,10]) do
        # we can bin on the fly
        values.should_not_receive(:<<)
        should_not_receive(:bin!)
      end.given(*nums).should emit_json(
        {"bin" => [ 0.0,1.0],  "count" => 7  },
        {"bin" => [ 1.0,5.0],  "count" => 14 },
        {"bin" => [ 5.0,10.0], "count" => 29 }
      )
    end

    it "can extract the value to bin by from an object" do
      processor(by: 'data.n', min: 0).given(*json).should emit_json(
        {"bin" => [ 0.0, 50.0],  "count" => 3 },
        {"bin" => [ 50.0,100.0], "count" => 1 }
      )
    end

  end
end
