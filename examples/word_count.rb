require 'wukong'


Wukong.dataflow(:mapper) do
  splitter  = map    { |line| line.downcase.strip.split(/\W/) }
  cleaner   = reject { |word| word.length < 2                 }
  add_count = foreach{ |word| emit [word, 1].join("\t")       } 
  stdin > splitter > flatten > cleaner > add_count > stdout #  > splitter > flatten > cleaner > add_count > stdout
end

Wukong.processor(:accumulator) do
  attr_accessor :current, :count

  def reset!() @current = nil ; @count = 0 ; end

  def report_then_reset!
    emit [current, count] unless current.nil?
    reset!
  end

  def accumulate(word, seen)
    @current = word if @current.nil?
    @count  += seen
  end

  def process(pair)
    word, seen = pair
    report_then_reset! unless word == current
    accumulate(word, seen.to_i)
  end

end

Wukong.dataflow(:reducer) do
  from_tsv = map(label: 'from_tsv'){ |line|  line.split("\t") }
  to_tsv   = map(label: 'to_tsv')  { |tuple| tuple.join("\t") }

  stdin > from_tsv > accumulator > to_tsv > stdout
end

# # cat data/jabberwocky.txt | bin/wu-map examples/word_count.rb | sort  | bin/wu-red examples/word_count.rb | sort -rnk2 | head
