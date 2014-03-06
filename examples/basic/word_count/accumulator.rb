Wukong.processor(:accumulator) do
  attr_accessor :count, :current

  def reset!() @current = nil ; @count = 0 ; end

  def report_then_reset!(&blk)
    yield [current, count].join("\t") unless current.nil?
    reset!
  end

  def accumulate(word, seen)
    @current = word if @current.nil?
    @count  += seen
  end

  def process(pair, &blk)
    word, seen = pair.split("\t")
    report_then_reset!(&blk) unless word == current
    accumulate(word, seen.to_i)
  end
  
  def finalize(&blk)
    report_then_reset!(&blk)
  end
  
end
