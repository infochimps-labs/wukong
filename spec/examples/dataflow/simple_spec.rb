require 'spec_helper'
require 'wukong'
require 'wukong/local_runner'

load Pathname.path_to(:examples, 'dataflow/simple.rb')

describe 'Simple Example', :examples_spec => true, :helpers => true do

  it 'runs' do
    Wukong::LocalRunner.receive(:flow => Wukong.dataflow(:simple)).run(:default)
  end
end
