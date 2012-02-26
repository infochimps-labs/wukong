

flow(:word_count) do

  cleaner  = map{|s, line| s.emit line.gsub(/\W+/, ' ') }
  splitter = map{|s, line| line.split.each{|word| s.emit(word) } }

  source($stdin) | cleaner | splitter | reject{|word| word.length < 3 } | stdout
end
