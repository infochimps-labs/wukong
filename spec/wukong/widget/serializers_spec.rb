require 'spec_helper'

describe "Serializing" do

  context :to_json do
    
    let(:emittable)     { {"hi" => "there"} }
    let(:not_emittable) { {"n" => Float::INFINITY} }

    it_behaves_like 'a processor', :named => :to_json
    
    it "should handle valid records" do
      processor.given(emittable).should emit_json(emittable)
    end

    it "should skip bad records" do
      processor.given(not_emittable).should emit(0).records
    end
    
  end

  context :to_tsv do
    let(:emittable)     { ["foo", 2, :a] }
    let(:not_emittable) { nil            }

    it_behaves_like 'a processor', :named => :to_tsv
    
    it "should handle valid records" do
      processor.given(emittable).should emit_tsv(emittable.map(&:to_s))
    end
    
    it "should skip bad records" do
      processor.given(not_emittable).should emit(0).records
    end
  end
end

describe "Deserializing" do

  context :from_json do
    let(:parseable)     { '{"hi": "there"}' }
    let(:not_parseable) { '{"832323:'       }

    it_behaves_like 'a processor', :named => :from_json

    it "should handle valid records" do
      processor.given(parseable).should emit({'hi' => 'there'})
    end
    
    it "should skip bad records" do
      processor.given(not_parseable).should emit(0).records
    end
  end
  
  context :from_tsv do

    let(:parseable)     { "foo\t2\ta"    }
    let(:not_parseable) { nil            }

    it_behaves_like 'a processor', :named => :from_tsv
    
    it "should handle valid records" do
      processor.given(parseable).should emit(parseable.split("\t"))
    end
    
    it "should skip bad records" do
      processor.given(not_parseable).should emit(0).records
    end
  end
end

describe "Pretty printing" do

  context "JSON" do
    let(:parseable)     { '{"hi": "there"}' }
    let(:not_parseable) { '{"832323:'       }

    it_behaves_like 'a processor', :named => :pretty

    it "should prettify parseable records" do
      processor(:pretty).given(parseable).should emit_json({'hi' => 'there'})
    end

    it "should pass on non parseable records" do
      processor(:pretty).given(not_parseable).should emit(not_parseable)
    end
  end

  it "should pass on everything else" do
    processor(:pretty).given('foobar').should emit('foobar')
  end
end
