require 'spec_helper'

describe Wukong::Processor do

  let(:hsh) { { "hi" => "there", "top" => { "lower" => { "lowest" => "value" } } } }
  let(:ary) { ['1', 2, 'three'] }

  context :logger do
    it_behaves_like "a processor", :named => :logger

    it "logs each event at the 'info' level by default" do
      # log = mock("logger")
      # log.should_receive(:info).with('hi there')
      # log.should_receive(:info).with('buddy')
      processor(:logger) do
        # stub!(:log).and_return(log)
      end.given('hi there', 'buddy').should emit(0).records
    end

    it "logs each event at the a desired level set with an argument" do
      # log = mock("logger")
      # log.should_receive(:debug).with('hi there')
      # log.should_receive(:debug).with('buddy')
      processor(:logger, level: :debug) do
        # stub!(:log).and_return(log)
      end.given('hi there', 'buddy').should emit(0).records
    end
  end
  
  context :extract do
    subject { processor(:extract) }
    
    it_behaves_like 'a processor', :named => :extract

    context "on a string" do
      it "emits the string with no arguments" do
        processor(:extract).given('hi there', 'buddy').should emit('hi there', 'buddy')
      end
    end
    context "on a Fixnum" do
      it "emits the number with no arguments" do
        processor(:extract).given(3, 3.0).should emit(3, 3.0)
      end
    end
    context "on a Hash" do
      it "emits the hash with no arguments" do
        processor(:extract).given(hsh).should emit(hsh)
      end
      it "can extract a key" do
        processor(:extract, part: 'hi').given(hsh).should emit('there')
      end
      it "emits nil when the value of the key is nil" do
        processor(:extract, part: 'bye').given(hsh).should emit(nil)
      end
      it "can extract a nested key" do
        processor(:extract, part: 'top.lower.lowest').given(hsh).should emit('value')
      end
      it "emits nil when the value of this nested key is nil" do
        processor(:extract, part: 'foo.bar.baz').given(hsh).should emit(nil)
      end
    end
    context "on an Array" do
      it "emits the array with no arguments" do
        processor(:extract).given(ary).should emit(ary)
      end
      it "can extract the nth value with an integer argument" do
        processor(:extract, part: 2).given(ary).should emit(2)
      end
      it "can extract the nth value with a string argument" do
        processor(:extract, part: '2').given(ary).should emit(2)
      end
    end
    context "on JSON" do
      let(:garbage) { '{"239823:' }
      it "emits the JSON with no arguments" do
        processor(:extract).given_json(hsh).should emit_json(hsh)
      end
      it "will skip badly formed records" do
        processor(:extract).given(garbage).should emit(garbage)
      end
      it "can extract a key" do
        processor(:extract, part: 'hi').given_json(hsh).should emit('there')
      end
      it "can extract a nested key" do
        processor(:extract, part: 'top.lower.lowest').given_json(hsh).should emit('value')
      end
      it "emits nil when the record is missing the key" do
        processor(:extract, part: 'foo.bar.baz').given_json(hsh).should emit(nil)
      end
    end
    context "on delimited data" do
      it "emits the row with no arguments" do
        processor(:extract).given_delimited('|', ary).should emit(ary.map(&:to_s).join('|'))
      end
      it "can extract the nth value with an integer argument" do
        processor(:extract, part: 2, separator: '|').given_delimited('|', ary).should emit('2')
      end
      it "can extract nth value with a string argument" do
        processor(:extract, part: '2', separator: '|').given_delimited('|', ary).should emit('2')
      end
    end
    context "on TSV" do
      it "emits the TSV with no arguments" do
        processor(:extract).given_tsv(ary).should emit(ary.map(&:to_s).join("\t"))
      end
      it "can extract the nth value with an integer argument" do
        processor(:extract, part: 2).given_tsv(ary).should emit('2')
      end
      it "can extract the nth value with a string argument" do
        processor(:extract, part: '2').given_tsv(ary).should emit('2')
      end
    end
    context "on CSV" do
      it "emits the CSV with no arguments" do
        processor(:extract).given_csv(ary).should emit(ary.map(&:to_s).join(","))
      end
      it "can extract the nth value with an integer argument" do
        processor(:extract, part: 2, separator: ',').given_csv(ary).should emit('2')
      end
      it "can extract the nth value with a string argument" do
        processor(:extract, part: '2', separator: ',').given_csv(ary).should emit('2')
      end
    end
  end
end
