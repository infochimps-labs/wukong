require 'spec_helper'
require 'wukong'

describe_example_script(:parse_apache_logs, 'dataflow/parse_apache_logs.rb') do
  it 'runs' do
    Wukong::LocalRunner.run(subject, :default)
  end
end
