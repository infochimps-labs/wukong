require File.expand_path('../examples_helper', File.dirname(__FILE__))

ExampleUniverse.dataflow(:parsing) do
  doc <<-DOC
    Parses an apache log line into a structured model, emits it as JSON
  DOC

  input  :default, file_source(Pathname.path_to(:data, 'text/jabberwocky.txt'))
  output :dump,    file_sink(Pathname.path_to(:tmp, 'dataflow/simple_output.rb'))

  input(:default) > map{|str| str.reverse } > output(:dump)
end
