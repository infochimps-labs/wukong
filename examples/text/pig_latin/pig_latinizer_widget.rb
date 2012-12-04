Wukong.dataflow(:pig_latinizer) do
  doc <<-DOC
    Accepts plaintext documents posted to its HTTP listener,
    translates it into pig latin, and archives both the
    translated and original texts into a mysql database
  DOC

  input  :raw_texts,       http_listener(:port => 8300)
  output :original_texts,  mysql_sink
  output :latinized_texts, mysql_sink

  input(:raw_texts) > many_to_many([
      :original_texts,
      pig_latinizer > :latinized_texts
    ])
end
