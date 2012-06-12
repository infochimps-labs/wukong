require 'spec_helper'
require 'wukong'

describe_example_script(:parse_apache_logs, 'dataflow/parse_apache_logs.rb') do
  it 'runs' do
    out, err = Gorillib::TestHelpers.capture_output do
      Wukong::LocalRunner.receive(:flow => subject) do
        run :default
      end
    end
    out.string.split("\n").first.should =~ /\{\"ip_address\":\"[\d\.]+\",.*\"}/ 
  end
end
