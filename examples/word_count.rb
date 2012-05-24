#!/usr/bin/env ruby

require 'wukong'

# cat data/jabberwocky.txt | bin/wu-map examples/word_count.rb | sort  | bin/wu-red examples/word_count.rb | sort -rnk2 | head

Wukong.processor(:add_count) do
  def process(word)
    emit [word, 1]
  end
end

Wukong.processor(:accumulator) do
  attr_accessor :current, :count

  def setup()  reset! ; end
  
  def stop()   report_then_reset! ; end

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

Wukong.dataflow(:mapper) do
  splitter = map    { |line| line.downcase.strip.split(/\W/) }
  cleaner  = reject { |word| word.length < 2 }
  splitter > flatten > cleaner > add_count > to_tsv
end

Wukong.dataflow(:reducer) do
  from_tsv > accumulator > to_tsv
end
