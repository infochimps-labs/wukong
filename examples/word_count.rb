# cat data/jabberwocky.txt | bin/wu-map examples/tiny_count.rb | sort  | bin/wu-red examples/tiny_count.rb  | sort -n | tail

mapper do |input|
  cleaner  = map{|line| emit line.downcase.gsub(/\W+/, ' ').strip }

  splitter = map{|line| line.split.each{|word| emit(word) } }

  input | cleaner | splitter | reject{|word| word.length < 3 }
end

reducer do |input|
  input | map{|rec| emit [rec.length, rec.first] } | to_tsv
end
