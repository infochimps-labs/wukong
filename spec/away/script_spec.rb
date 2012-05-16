# require 'spec_helper'
# require 'wukong/runner/hadoop'
#
# describe "Wukong::Runner::Hadoop" do
#   before do
#     ARGV.replace []
#     @script = Wukong::Script.new 'mapper', 'reducer'
#   end
#
#   describe 'initialize' do
#     it 'sets :reduce_tasks to 0 if reducer_klass is nil and no reduce_command or explicit setting' do
#       @script = Wukong::Script.new 'mapper', nil
#       @script.options[:reduce_tasks].should == 0
#     end
#     it 'respects :reduce_tasks if set even if reducer_klass is nil' do
#       @script = Wukong::Script.new 'mapper', nil, :reduce_tasks => 1
#       @script.options[:reduce_tasks].should == 1
#     end
#     it "doesn't set :reduce_tasks reduce_command is given" do
#       @script = Wukong::Script.new 'mapper', nil, :reduce_command => 1
#       @script.options[:reduce_tasks].should be_nil
#     end
#     it 'sets mapper_klass in initializer' do
#       @script.mapper_klass.should == 'mapper'
#     end
#     it 'sets reducer_klass in initializer' do
#       @script.reducer_klass.should == 'reducer'
#     end
#   end
#
#   describe 'child processes' do
#     it 'calls self if a mapper_klass is set' do
#       @script.should_receive(:ruby_interpreter_path).and_return('/path/to/ruby')
#       @script.should_receive(:this_script_filename).and_return('/path/to/this_script')
#       @script.map_command.should == %Q{/path/to/ruby /path/to/this_script --map }
#     end
#     it 'calls default_mapper if nil mapper_klass and no map_command is set' do
#       @script = Wukong::Script.new nil, 'reducer', :default_mapper => 'default_mapper'
#       @script.map_command.should == 'default_mapper'
#     end
#     it 'calls map_command if nil mapper_klass and map_command is set' do
#       @script = Wukong::Script.new nil, 'reducer', :map_command => 'map_command', :default_mapper => 'default_mapper'
#       @script.map_command.should == 'map_command'
#     end
#
#     it 'calls self if a reducer_klass is set' do
#       @script.should_receive(:ruby_interpreter_path).and_return('/path/to/ruby')
#       @script.should_receive(:this_script_filename).and_return('/path/to/this_script')
#       @script.reduce_command.should == %Q{/path/to/ruby /path/to/this_script --reduce }
#     end
#     it 'calls default_reducer if nil reducer_klass and no reduce_command is set' do
#       @script = Wukong::Script.new 'mapper', nil, :default_reducer => 'default_reducer'
#       @script.reduce_command.should == 'default_reducer'
#     end
#     it 'calls reduce_command if nil reducer_klass and reduce_command is set' do
#       @script = Wukong::Script.new 'mapper', nil, :reduce_command => 'reduce_command', :default_reducer => 'default_reducer'
#       @script.reduce_command.should == 'reduce_command'
#     end
#
#     it 'runs script | sort | script when in local mode' do
#       @script.should_receive(:run_mode).and_return('local')
#       @script.should_receive(:map_command).and_return('map_command')
#       @script.should_receive(:reduce_command).and_return('reduce_command')
#       @script.runner_command("/path/in", "/path/out").should == %Q{ cat '/path/in' | map_command | sort | reduce_command > '/path/out'}
#     end
#
#     it 'calls out to hadoop when in non-local mode' do
#       @script.should_receive(:run_mode).and_return('hadoop')
#       @script.should_receive(:hadoop_command).and_return('hadoop_command whee!')
#       @script.runner_command("/path/in", "/path/out").should == 'hadoop_command whee!'
#     end
#   end
#
#   describe 'runner phase'
#   it 'preserves non-internal-to-wukong params in non_wukong_params' do
#     @script.options[:foo] = 'bar'
#     @script.non_wukong_params.should == "--foo=bar"
#   end
#
#
# end
