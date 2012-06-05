require File.expand_path('../examples_helper', File.dirname(__FILE__))

ExampleUniverse.dataflow(:simple) do
  doc <<-DOC
    A stupidly simple dataflow: reverses each input string
  DOC

  input  :default, file_source(Pathname.path_to(:data, 'text/jabberwocky.txt'))
  output :dump,    file_sink(Pathname.path_to(:tmp, 'dataflow/simple_output.rb'))

  input(:default) > map{|str| str.reverse } > output(:dump)
end
