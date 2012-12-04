require_relative 'tokenizer'
require_relative 'accumulator'

Wukong.dataflow(:word_count) do
  tokenizer(min_length: 3) > sort(label: 'first_sort') > accumulator > sort(on: 1, numeric: true, reverse: true)
end
