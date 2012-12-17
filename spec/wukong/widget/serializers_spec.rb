require 'spec_helper'

shared_context 'serializers', serializer: true do
  let(:bad_record){ nil }
  let(:serializer){ create_processor(self.class.top_level_description, on_error: :skip) }
end

shared_examples_for 'a serializer' do
  it_behaves_like 'a processor'
end

shared_examples_for 'a serializer that complains on bad recors', :handles_errors => true do
  it 'handles errors on bad records' do
    serializer.should_receive(:handle_error).with(bad_record, a_kind_of(Exception)).and_return(nil)
    serializer.given(bad_record).should emit(0).records
  end
end

describe :to_json, serializer: true do
  let(:valid_record) { { hi: 'there' }        }
  it 'serializes valid records' do
    serializer.given(valid_record).should emit('{"hi":"there"}')
  end
  
  context 'pretty' do
    let(:serializer){ create_processor(:to_json, pretty: true) }
    
    it 'prettifies valid records' do
      serializer.given(valid_record).output.first.should include("\n")
    end  
  end

  context 'given a model' do
    let(:json_record) {  '{"foo":"bar"}'                      }
    let(:valid_model) { double('model', to_json: json_record) }
    
    it 'defers to the model to serialize' do
      valid_model.should_receive(:to_json).and_return(json_record)
      serializer.given(valid_model).should emit(json_record)
    end
  end
end

describe :to_tsv, serializer: true, handles_errors: true do
  let(:valid_record) { ["foo", 2, :a] }
  
  it 'serializes valid records' do
    serializer.given(valid_record).should emit("foo\t2\ta")
  end

  context 'given a model' do
    let(:tsv_record)  { "foo\tbar\tbaz"                     }
    let(:valid_model) { double('model', to_tsv: tsv_record) }
    
    it 'defers to the model to serialize' do
      valid_model.should_receive(:to_tsv).and_return(tsv_record)
      serializer.given(valid_model).should emit(tsv_record)
    end
  end
end

describe :from_json, serializer: true, handles_errors: true do
  let(:valid_record) { '{"hi": "there"}' }
  let(:bad_record)   { '{"832323:'       }
  
  it 'deserializes valid records' do
    serializer.given(valid_record).should emit({'hi' => 'there'})
  end  

  context 'given a model' do
    let(:wire_format) { { foo: 'bar' }                          }
    let(:valid_model) { double('model', from_json: wire_format) }
    
    it 'defers to the model to serialize' do
      valid_model.should_receive(:from_json).and_return(wire_format)
      serializer.given(valid_model).should emit(wire_format)
    end
  end
end

describe :from_tsv, serializer: true, handles_errors: true do
  let(:valid_record) { "foo\t2\ta" }
  
  it 'deserializes valid records' do
    serializer.given(valid_record).should emit(['foo', '2', 'a' ])
  end

  context 'given a model' do
    let(:wire_format) { { foo: 'bar' }                         }
    let(:valid_model) { double('model', from_tsv: wire_format) }
    
    it 'defers to the model to serialize' do
      valid_model.should_receive(:from_tsv).and_return(wire_format)
      serializer.given(valid_model).should emit(wire_format)
    end
  end
end

describe :to_inspect do
  it_behaves_like 'a processor'
end

describe :recordize, serializer: true, handles_errors: true do
  let(:model_instance) { double('model')                                                   }
  let(:model_klass)    { double('model_def', receive: model_instance)                      }
  let(:serializer)     { create_processor(:recordize, model: model_klass, on_error: :skip) }
  let(:valid_record)   { { foo: 'bar' }                                                    }

  it 'recordizes valid records' do
    serializer.given(valid_record).should emit(model_instance)
  end
end
