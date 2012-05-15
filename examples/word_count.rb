#!/usr/bin/env ruby

require 'wukong'

# cat data/jabberwocky.txt | bin/wu-map examples/word_count.rb | sort  | bin/wu-red examples/word_count.rb  | sort -nk2 | tail

Wukong.dataflow(:main) do
  cleaner  = map{|line| line.downcase.strip }
  splitter = map{|line| line.split(/\W/)    }

  input >
    cleaner > splitter > flatten >
    reject{|word| word.length < 3 } >
    output
end

Wukong::LocalRunner.new do
  input  Wukong::Widget::Stdin
  output Wukong::Widget::Stdout
  graph  Wukong.dataflow(:main)
end.run
