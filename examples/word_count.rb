# cat examples/jabberwocky.txt | bin/wu-local examples/word_count.rb | sort -rnk2 | head

require 'wukong'

Wukong.processor(:accumulator) do
  attr_accessor :count, :current

  def reset!() @current = nil ; @count = 0 ; end

  def report_then_reset!(&blk)
    yield [current, count] unless current.nil?
    reset!
  end

  def accumulate(word, seen)
    @current = word if @current.nil?
    @count  += seen
  end

  def process(pair, &blk)
    word, seen = pair
    report_then_reset!(&blk) unless word == current
    accumulate(word, seen.to_i)
  end
  
  def finalize(&blk)
    report_then_reset!(&blk)
  end
  
end

Wukong.dataflow(:word_count) do
  map(label:    :splitter)  { |line|  line.downcase.strip.split(/\W/) }
  reject(label: :cleaner)   { |word|  word.length < 3                 } 
  map(label:    :add_count) { |word|  [word, 1].join("\t")            }
  map(label:    :from_tsv)  { |line|  line.split("\t")                }
  map(label:    :to_tsv)    { |tuple| tuple.join("\t")                } 
    
  splitter > flatten > cleaner > add_count > sort > from_tsv > accumulator > to_tsv
end
