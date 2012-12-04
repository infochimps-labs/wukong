require File.expand_path('../examples_helper', File.dirname(__FILE__))

Wukong.dataflow(:simple) do
  doc <<-DOC
    A stupidly simple dataflow: reverses each input string
  DOC

  file_source(Pathname.path_to(:data, 'text/jabberwocky.txt')) >
    map{|str| str.reverse } >
    file_sink(Pathname.path_to(:tmp, 'dataflow/simple_output.rb'))

end
