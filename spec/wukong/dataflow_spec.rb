# require 'spec_helper'
# require 'wukong'

describe Wukong::Dataflow do

  # context '#handle_dsl_methods_for' do
  #   let(:block_arg){ ->(rec){ transform_into('kitty pryde') } } 
  #   it 'accepts a block and assigns it to an :action key' do
  #     graph_builder.send(:mystique, &block_arg)      
  #     graph_builder.stages[:mystique].serialize.should include(action: block_arg)
  #   end
  # end

end

# describe Wukong::Chain, :helpers => true do
#   subject{ described_class.new }
#   let(:test_re){  /^f/ }

#   context 'examples' do

#     subject{
#       test_sink = test_sink()
#       Wukong.chain(:integers) do
#         set_source Wukong::Source::Integers.new(:qty => 100)
#         set_sink   test_sink

#         input(:default)    >
#           map{|i| i.to_s } >
#           re(/..+/)        >
#           map(&:reverse)   >
#           limit(20)        >
#           output(:default)
#       end
#       Wukong::LocalRunner.receive(:flow => Wukong.chain(:integers))
#     }

#     it 'runs' do
#       subject.run(:default)
#       subject.flow.output(:default).records.should == ["01", "11", "21", "31", "41", "51", "61", "71", "81", "91", "02", "12", "22", "32", "42", "52", "62", "72", "82", "92"]
#     end

#   end

#   context '#select' do
#     it 'evaluates block arg on each record, selecting if true' do
#       result = subject.select{|rec| rec.odd? }
#       result.should      be_a(Wukong::Widget::Select)
#       result.should      be_select(3)
#       result.should_not  be_select(2)
#     end

#     it 'given proc as plain arg, evaluates it on each record, selecting if true' do
#       result = subject.select( ->(rec){ rec.odd? } )
#       result.should      be_a(Wukong::Widget::Select)
#       result.should      be_select(3)
#       result.should_not  be_select(2)
#     end

#     it 'adds a stage to the dataflow' do
#       p subject.stages
#       subject.stages.should_receive(:receive_item).with(:select_1, kind_of(Wukong::Widget::Select))
#       subject.select{|rec| rec =~ /^h/ }.should be_a(Wukong::Widget::Select)
#       p subject.stages
#     end
#   end

#   context '#reject' do
#     it 'evaluates block arg on each record, rejecting if true' do
#       result = subject.reject{|rec| rec.odd? }
#       result.should      be_a(Wukong::Widget::Reject)
#       result.should_not  be_select(3)
#       result.should      be_select(2)
#     end

#     it 'given proc as plain arg, evaluates it on each record, rejecting if true' do
#       result = subject.reject( ->(rec){ rec.odd? } )
#       result.should      be_a(Wukong::Widget::Reject)
#       result.should_not  be_select(3)
#       result.should      be_select(2)
#     end

#     it 'adds a stage to the dataflow' do
#       subject.should_receive(:receive_item).with(:reject_0, kind_of(Wukong::Widget::Reject))
#       subject.reject{|rec| rec =~ /^h/ }.should be_a(Wukong::Widget::Reject)
#     end
#   end
# end
