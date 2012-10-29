# require 'spec_helper'
# require 'wukong'

# describe 'wukong', :helpers => true do

#   describe 'json' do
#     let(:json_data  ){ {'abc' => 'def'} }
#     let(:json_string){ '{"abc":"def"}'  }

#     describe Wukong::Widget::FromJson do
#       it 'decodes' do
#         subject.should_receive(:emit).with(json_data)
#         subject.process(json_string)
#       end
#     end

#     describe Wukong::Widget::ToJson do
#       it 'encodes' do
#         subject.should_receive(:emit).with(json_string)
#         subject.process(json_data)
#       end

#       it 'emits metadata in the _metadata key if record has _metadata' do
#         test_model_class.send(:include,Wukong::Event)
#         test_model._metadata = { :a => :b }
#         subject.should_receive(:emit).with('{"smurfiness":99,"_type":"anon","_metadata":{"a":"b"}}')
#         subject.process(test_model)
#       end
#     end
#   end

#   describe 'tsv' do
#     let(:tsv_data  ){ ['abc', 'def'] }
#     let(:tsv_string){ "abc\tdef"     }

#     describe Wukong::Widget::FromTsv do
#       it 'decodes' do
#         subject.should_receive(:emit).with(tsv_data)
#         subject.process(tsv_string)
#       end
#     end

#     describe Wukong::Widget::ToTsv do
#       it 'encodes' do
#         subject.should_receive(:emit).with(tsv_string)
#         subject.process(tsv_data)
#       end
#     end
#   end

# end
