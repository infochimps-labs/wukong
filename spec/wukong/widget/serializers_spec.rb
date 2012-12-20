require 'spec_helper'

describe "Serializers" do

  describe :to_json do
    it_behaves_like 'a processor', :named => :to_json
    
    let(:valid_record)    { { hi: 'there' }                          }
    let(:record_as_json)  { '{"hi":"there"}'                         }
    let(:model_as_json)   { '{"model":"json"}'                       }
    let(:valid_model)     { double('model', to_json: model_as_json)  }
    
    it 'serializes records to JSON' do
      processor.given(valid_record).should emit(record_as_json)
    end
    
    it 'serializes records as pretty JSON when asked' do
      processor(:pretty => true).given(valid_record).output.first.should include("\n")
    end

    it 'defers to models to let them serialize themselves as JSON' do
      processor.given(valid_model).should emit(model_as_json)
    end
  end


  describe :from_json do
    it_behaves_like 'a processor', :named => :from_json
    
    let(:valid_json)   { '{"hi": "there"}'                        }
    let(:json_parsed)  { {"hi" => "there"}                        }
    let(:invalid_json) { '{"832323:'                              }
    
    it 'deserializes valid JSON' do
      processor.given(valid_json).should emit(json_parsed)
    end
    
    it 'handles errors on invalid JSON' do
      processor { |proc| proc.should_receive(:handle_error).with(invalid_json, kind_of(Exception)) }.given(invalid_json).should emit(0).records
    end
  end
  
  describe :to_tsv do
    it_behaves_like 'a processor', :named => :to_tsv
    
    let(:valid_record)   { ["foo", 2, :a]  }
    let(:invalid_record) { nil             }
    let(:record_as_tsv)  { "foo\t2\ta"     }
    let(:model_as_tsv)   { "foo\tbar\tbaz" }
    let(:valid_model)    { double('model', to_tsv: model_as_tsv) }
    
    it 'serializes records to JSON' do
      processor.given(valid_record).should emit(record_as_tsv)
    end

    it 'defers to models to let them serialize themselves as JSON' do
      processor.given(valid_model).should emit(model_as_tsv)
    end

    it 'handles errors on bad records' do
      processor { |proc| proc.should_receive(:handle_error) }.given(invalid_record).should emit(0).records
    end
  end

  describe :from_tsv, serializer: true, handles_errors: true do
    it_behaves_like 'a processor', :named => :from_tsv
    
    let(:valid_tsv)   { "foo\t2\ta"       }
    let(:tsv_parsed)  { ["foo", "2", "a"] }
    let(:invalid_tsv) { nil               }
    
    it 'deserializes valid TSV' do
      processor.given(valid_tsv).should emit(tsv_parsed)
    end

    it "handles errors on invalid TSV" do
      processor { |proc| proc.should_receive(:handle_error).with(invalid_tsv, kind_of(Exception)) }.given(invalid_tsv).should emit(0).records
    end
  end

  describe :to_inspect do
    it_behaves_like 'a processor', :named => :to_inspect
    
    let(:valid_record)      { {"a" => 1 }                                   }
    let(:record_as_inspect) { valid_record.inspect                          }
    let(:model_as_inspect)  { '<Model #13e233>'                             }
    let(:valid_model)       { double('model', inspect: model_as_inspect)    }
    
    it 'serializes records via inspect' do
      processor.given(valid_record).should emit(record_as_inspect)
    end

    it 'defers to models to let them inspect themselves' do
      processor.given(valid_model).should emit(model_as_inspect)
    end
  end

  describe :recordize do
    let(:model_instance) { double('model')                                                   }
    let(:model_klass)    { double('model_def', receive: model_instance)                      }
    let(:serializer)     { processor(:recordize, model: model_klass, on_error: :skip)        }
    let(:valid_record)   { { foo: 'bar' }                                                    }
    let(:invalid_record) { [1,2,3]                                                           }

    it 'recordizes valid records' do
      processor(model: model_klass).given(valid_record).should emit(model_instance)
    end

    it 'handles errors on invalid models' do
      processor(model: model_klass) { |proc| proc.should_receive(:handle_error).with(invalid_record, kind_of(Exception)) }.given(invalid_record).should emit(0).records
    end
    
  end
end
