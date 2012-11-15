require 'spec_helper'

describe "Processors" do

  let(:hsh) { { "hi" => "there", "top" => { "lower" => { "lowest" => "value" } } } }
  let(:ary)       { ['1', 2, 'three'] }
  
  context :extract do
    it_behaves_like 'a processor', :named => :extract

    context "on a string" do
      it "will yield the string with no arguments" do
        processor(:extract).given('hi there').should emit('hi there')
      end
    end
    context "on a Fixnum" do
      it "will yield the number with no arguments" do
        processor(:extract).given(3).given(3.0).should emit(3, 3.0)
      end
    end
    context "on a Hash" do
      it "will yield the hash with no arguments" do
        processor(:extract).given(hsh).should emit(hsh)
      end
      it "will yield a value in the hash when it maches its argument" do
        processor(:extract, part: 'hi').given(hsh).should emit('there')
      end
      it "will yield the object with a key argument" do
        processor(:extract, part: 'hi').given(hsh).should emit('there')
      end
      it "will yield the object with a nested key argument" do
        processor(:extract, part: 'top.lower.lowest').given(hsh).should emit('value')
      end
      it "will skip a record missing the a nested key value" do
        processor(:extract, part: 'foo.bar.baz').given(hsh).should emit(nil)
      end
    end
    context "on an Array" do
      it "will yield the array with no arguments" do
        processor(:extract).given(ary).should emit(ary)
      end
      it "will yield the nth value with an integer argument" do
        processor(:extract, part: 2).given(ary).should emit(2)
      end
      it "will yield the nth value with a string argument" do
        processor(:extract, part: '2').given(ary).should emit(2)
      end
    end
    context "on JSON" do
      let(:garbage) { '{"239823:' }
      it "will yield the JSON with no arguments" do
        processor(:extract).given(hsh).as_json.should emit(hsh).as_json
      end
      it "will not skip badly formed records" do
        processor(:extract).given(garbage).should emit(garbage)
      end
      it "will yield the object with a key argument" do
        processor(:extract, part: 'hi').given(hsh).as_json.should emit('there')
      end
      it "will yield the object with a nested key argument" do
        processor(:extract, part: 'top.lower.lowest').given(hsh).as_json.should emit('value')
      end
      it "will skip a record missing the a nested key value" do
        processor(:extract, part: 'foo.bar.baz').given(hsh).as_json.should emit(nil)
      end
    end
    context "on TSV" do
      it "will yield the TSV with no arguments" do
        processor(:extract).given(ary).as_tsv.should emit(ary.map(&:to_s).join("\t"))
      end
      it "will yield the nth value with an integer argument" do
        processor(:extract, part: 2).given(ary).as_tsv.should emit('2')
      end
      it "will yield the nth value with a string argument" do
        processor(:extract, part: '2').given(ary).as_tsv.should emit('2')
      end
    end
    context "on delimited data" do
      it "will yield the row with no arguments" do
        processor(:extract).given(ary).delimited(',').should emit(ary.map(&:to_s).join(','))
      end
      it "will yield the nth value with an integer argument" do
        processor(:extract, part: 2, separator: ',').given(ary).delimited(',').should emit('2')
      end
      it "will yield the nth value with a string argument" do
        processor(:extract, part: '2', separator: ',').given(ary).delimited(',').should emit('2')
      end
    end
  end
end


# describe 'widgets' do
#   before(:each){ load 'wukong/widget/processors.rb' }
  
#   context Wukong::Processor::Null do
    
#     it 'is registered' do
#       Wukong.registry.should be_registered(:null)
#     end
    
#     context '#process' do
#       it 'returns nothing when process is called' do
#         subject.process('Nothing moves the Blob!').should be_nil
#       end
#     end
#   end

#   # context Wukong::Processor::Foreach do

#   #   it 'is registered' do
#   #     Hanuman::GlobalRegistry.should be_registered(:foreach)
#   #   end
    
#   #   context '#process' do
#   #     it 'calls its action method when process is called' do
#   #       subject.should_receive(:perform_action).with('To Me, My X-men')
#   #       subject.process('To Me, My X-men')
#   #     end
#   #   end
#   # end
  
#   context Wukong::Processor::Map do
    
#     it 'is registered' do
#       Hanuman::GlobalRegistry.should be_registered(:map)
#     end
    
#     context '#process' do
#       it 'calls its action method and emits the result when process is called' do
#         subject.should_receive(:perform_action).with("I'm the best there is at what I do").and_return("But what I do isn't very nice")
#         subject.should_receive(:emit).with("But what I do isn't very nice")
#         subject.process("I'm the best there is at what I do")
#       end
#     end
#   end
  
#   context Wukong::Processor::Flatten do

#     it 'is registered' do
#       Hanuman::GlobalRegistry.should be_registered(:map)
#     end
    
#     context '#process' do
#       context 'enumerable record' do
#         it 'emits each record separately, in order' do
#           subject.should_receive(:emit).with('Cable').ordered
#           subject.should_receive(:emit).with('Sabretooth').ordered
#           subject.should_receive(:emit).with('Bishop').ordered      
#           subject.process(%w[Cable Sabretooth Bishop])
#         end
#       end
      
#       context 'single record' do
#         it 'emits the record singly' do
#           subject.should_receive(:emit).with('Archangel')
#           subject.process('Archangel')
#         end
#       end
#     end
#   end
# end


