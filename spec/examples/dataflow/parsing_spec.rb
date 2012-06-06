require 'spec_helper'
require 'wukong'

describe_example_script(:parse_apache_logs, 'dataflow/parse_apache_logs.rb') do
  it 'runs' do
    out, err = Gorillib::TestHelpers.capture_output do
      Wukong::LocalRunner.receive(:flow => subject) do
        run :default
      end
    end
    out.string.split("\n").first.should == "{\"ip_address\":\"127.0.0.1\",\"junk_1\":\"-\",\"junk_2\":\"-\",\"log_timestamp\":1176190751.000000000,\"http_method\":\"GET\",\"path\":\"\\/\",\"protocol\":\"HTTP\\/1.1\",\"response_code\":500,\"size\":606,\"referer\":\"-\",\"user_agent\":\"Mozilla\\/5.0 (X11; U; Linux i686; en-US; rv:1.8.1.3) Gecko\\/20061201 Firefox\\/2.0.0.3 (Ubuntu-feisty)\"}" 
  end
end
