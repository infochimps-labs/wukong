require 'spec_helper'
require 'wukong'

describe_example_script(:simple, 'dataflow/simple.rb') do
  it 'runs' do
    Wukong::LocalRunner.run(subject, :default)
  end
end
