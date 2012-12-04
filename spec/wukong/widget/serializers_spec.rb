require 'spec_helper'

shared_context 'serializers', serializer: true do
  let(:bad_record){ nil }
  let(:serializer){ create_processor(self.class.top_level_description) }  

  it_behaves_like 'a serializer'
end

shared_examples_for 'a serializer' do
  it_behaves_like 'a processor'

  it 'handles errors on bad records' do
    serializer.should_receive(:handle_error).with(bad_record, a_kind_of(Exception)).and_return(nil)
    serializer.given(bad_record).should emit(0).records
  end
end

describe :to_json, serializer: true do
  let(:valid_record) { { hi: 'there' }        }
  let(:bad_record)   { { no: Float::INFINITY} }

  it 'serializes valid records' do
    serializer.given(valid_record).should emit('{"hi":"there"}')
  end

  context 'pretty' do
    let(:serializer){ create_processor(:to_json, pretty: true) }
    
    it 'prettifies valid records' do
      serializer.given(valid_record).should emit("{\n  \"hi\": \"there\"\n}")
    end  
  end
end

describe :to_tsv, serializer: true do
  let(:valid_record) { ["foo", 2, :a] }
  
  it 'serializes valid records' do
    serializer.given(valid_record).should emit("foo\t2\ta")
  end
end

describe :from_json, serializer: true do
  let(:valid_record) { '{"hi": "there"}' }
  let(:bad_record)   { '{"832323:'       }
  
  it 'deserializes valid records' do
    serializer.given(valid_record).should emit({'hi' => 'there'})
  end  
end

describe :from_tsv, serializer: true do
  let(:valid_record) { "foo\t2\ta" }
  
  it 'deserializes valid records' do
    serializer.given(valid_record).should emit(['foo', '2', 'a' ])
  end
end

