require 'spec_helper'
# require 'wukong'

# describe_example_script(:parse_apache_logs, 'dataflow/parse_apache_logs.rb') do
#   it 'runs' do
#     subject = Wukong.dataflow(:parse_apache_logs)
#     out, err = Gorillib::TestHelpers.capture_output do
#       Wukong::LocalRunner.receive(:flow => subject) do
#         run :default
#       end
#     end
#     out.string.split("\n").first.should == "127.0.0.1 - - [10/Apr/2007:10:39:11 +0300] \"GET / HTTP/1.1\" 500 606 \"-\" \"Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1.3) Gecko/20061201 Firefox/2.0.0.3 (Ubuntu-feisty)\"\t"
#   end
# end
