# cat README.md | bin/wu-map examples/tiny_count.rb | sort  | bin/wu-red examples/tiny_count.rb  | sort -n

mapper do |input|
  cleaner  = map{|line| emit line.gsub(/\W+/, ' ') }
  splitter = map{|line| line.split.each{|word| emit(word) } }

  input | cleaner | splitter | reject{|word| word.length < 3 }
end

reducer do |input|
  input | map{|rec| emit [rec.length, rec.first] } | to_tsv
end
