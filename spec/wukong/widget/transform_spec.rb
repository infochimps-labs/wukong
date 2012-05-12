require File.expand_path('../spec_helper', File.dirname(__FILE__))
require 'wukong'

# describe :transforms, :helpers => true do
#   describe Wukong::Transform do
#     context 'registry' do
#       it 'contains standard transforms' do
#         [:identity, :counter, :limit].each do |handle|
#           klass = "Wukong::Transform::#{handle.to_s.camelize}".constantize
#           Wukong.transform_klass(handle).should == klass
#         end
#       end
#     end
# 
# 
#     context '#select' do
#       it 'creates a RegexpFilter given a regexp' do
#         subject.select(test_re)
#         subject.next_stage.should      be_a(Wukong::Filter::RegexpFilter)
#         subject.next_stage.re.should   be(test_re)
#         subject.next_stage.should      be_accept("hello")
#         subject.next_stage.should_not  be_accept("your mom")
#       end
#     
#       it 'creates a ProcFilter given a proc' do
#         test_proc = ->(rec){ rec.odd? }
#         subject.select(test_proc)
#         subject.next_stage.should      be_a(Wukong::Filter::ProcFilter)
#         subject.next_stage.should      be_accept(3)
#         subject.next_stage.should_not  be_accept(2)
#       end
#     
#       it 'creates a ProcFilter given a proc' do
#         subject.select{|rec| rec.odd? }
#         subject.next_stage.should      be_a(Wukong::Filter::ProcFilter)
#         subject.next_stage.should      be_accept(3)
#         subject.next_stage.should_not  be_accept(2)
#       end
#     end
#     
#     context '#reject' do
#       it 'creates a RegexpFilter given a regexp' do
#         subject.reject(test_re)
#         subject.next_stage.should      be_a(Wukong::Filter::RegexpFilter)
#         subject.next_stage.re.should   be(test_re)
#         subject.next_stage.should_not  be_accept("hello")
#         subject.next_stage.should      be_accept("your mom")
#       end
#     
#       it 'creates a ProcFilter given a proc' do
#         test_proc = ->(rec){ rec.odd? }
#         subject.reject(test_proc)
#         subject.next_stage.should      be_a(Wukong::Filter::ProcFilter)
#         subject.next_stage.should_not  be_accept(3)
#         subject.next_stage.should      be_accept(2)
#       end
#     
#       it 'creates a ProcFilter given a proc' do
#         subject.reject{|rec| rec.odd? }
#         subject.next_stage.should      be_a(Wukong::Filter::ProcFilter)
#         subject.next_stage.should_not  be_accept(3)
#         subject.next_stage.should      be_accept(2)
#       end
#     end

#   end
#   describe Wukong::Transform do
#     context "has stub methods so everything can call super" do
#       it{ should respond_to(:call) }
#       it{ should respond_to(:emit) }
#       it{ should respond_to(:finally) }
#     end
#   end
#
#   describe Wukong::Transform::Identity do
#     it 'outputs every record, unmodified' do
#       subject.should_receive(:emit).with(mock_record)
#       subject.call(mock_record)
#     end
#   end
#
#   describe Wukong::Transform::Counter do
#     context "when first created" do
#       its(:count){ should eq(0) }
#     end
#
#     context "#initialize" do
#       it 'calls reset!' do
#         described_class.any_instance.should_receive(:reset!)
#         described_class.new
#       end
#     end
#
#     context "#reset" do
#       it 'sets the count to 0' do
#         3.times{ subject.call("hi") }
#         subject.count.should eq(3)
#         subject.reset!
#         subject.count.should eq(0)
#       end
#     end
#   end
#
#   describe Wukong::Transform::Map do
#     let(:test_proc){ ->(rec){ rec.reverse } }
#     subject{ described_class.new( test_proc ) }
#
#     it 'emits the output of the proc' do
#       subject.should_receive(:emit).with("won ytineres")
#       subject.call("serenity now")
#     end
#   end
#
#   describe Wukong::Transform::Group do
#
#     # it 'works in an example flow flow' do
#     #   test_sink = test_array_sink()
#     #   example_input   = %w[ a a a    b b      c        d d     ]
#     #   expected_output =   [ ['a',3], ['b',2], ['c',1], ['d',2] ]
#     #   Wukong.flow(:simple) do
#     #     source(:iter, example_input ) | group | counter | test_sink
#     #   end.run
#     #   test_sink.records.should == expected_output
#     # end
#
#     # it 'calls end_group at the end'
#     #
#     # it 'on an empty stream'
#
#   end
#
# end
