# -*- coding: utf-8 -*-
require 'jeweler'
Jeweler::Tasks.new do |s|
  s.name = "wukong"
  s.executables = FileList['bin/*'].pathmap('%f')
  s.summary = "Wukong makes Hadoop so easy a chimpanzee can use it."
  s.email = "flip@infochimps.org"
  s.homepage = "http://github.com/mrflip/wukong"
  s.description = <<DESC
  Treat your dataset like a:

      * stream of lines when it’s efficient to process by lines
      * stream of field arrays when it’s efficient to deal directly with fields
      * stream of lightweight objects when it’s efficient to deal with objects

  Wukong is friends with Hadoop the elephant, Pig the query language, and the cat on your command line.
DESC
  s.authors = ["Philip (flip) Kromer"]
  s.files =  FileList["\w*", "{config,doc,examples,spec,lib}/**/*"].reject{|file| file.to_s =~ %r{config/private\.yaml} }
end
