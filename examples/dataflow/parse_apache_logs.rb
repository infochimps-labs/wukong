require File.expand_path('../examples_helper', File.dirname(__FILE__))
require Pathname.path_to(:examples, 'dataflow/apache_log_line')

ExampleUniverse.dataflow(:parse_apache_logs) do
  doc <<-DOC
    Parses an apache log line into a structured model, emits it as JSON
  DOC

  input  :default, file_source(Pathname.path_to(:data, 'log/sample_apache_log.log'))
  output :dump,    stdout 

  input(:default) >
    map{|line| ApacheLogLine.make(line) or BadRecord.make(line) } >
    to_json >
    output(:dump)
  
end
