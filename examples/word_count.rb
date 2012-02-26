

flow(:mapper) do

  cleaner  = map{|line| emit line.gsub(/\W+/, ' ') }
  splitter = map{|line| line.split.each{|word| emit(word) } }

  source($stdin) | cleaner | splitter | reject{|word| word.length < 3 } > stdout
end

flow(:reducer) do
  bundle = make(:sink, :array_capture)

  source($stdin) | bundle
end
