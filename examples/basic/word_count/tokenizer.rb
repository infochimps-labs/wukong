Wukong.processor(:tokenizer) do

  field :min_length, Integer, :default => 1

  def process(record)
    words   = record.downcase.strip.split(/\W/)
    lengthy = words.select{ |word| word.length >= min_length }
    lengthy.each do |word|
      yield [ word, 1 ].join("\t")
    end
  end

end
