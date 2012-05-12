#!/usr/bin/env ruby

require 'wukong'

# cat data/jabberwocky.txt | bin/wu-map examples/word_count.rb | sort  | bin/wu-red examples/word_count.rb  | sort -nk2 | tail

Wukong.mapred do

  chain(:mapper) do
    cleaner  = map{|line|     line.downcase.gsub(/\W+/, ' ').strip }
    splitter = project{|line| line.split.each{|word| emit(word) } }
    sizer    = reject{|word|  word.length < 3 }
    input > cleaner > splitter > sizer > output
  end

  input > chain(:mapper) > output
end

# mapper do |input|
#   cleaner  = map{|line| line.downcase.gsub(/\W+/, ' ').strip }
#
#   splitter = project{|line| line.split.each{|word| emit(word) } }
#
#   input | cleaner | splitter | reject{|word| word.length < 3 }
# end
#
# # implicit group
#
# reducer do |group|
#   group | counter  |    # emit count of each group
#     map(&:reverse) |    # swap to make [count, term]
#     to_tsv              # output as TSV
# end
