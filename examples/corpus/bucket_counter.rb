
class BucketCounter
  BUCKET_SIZE = 2**24
  attr_reader :total

  def initialize
    @hsh = Hash.new{|h,k| h[k] = 0 }
    @total = 0
  end

  # def [] val
  #   @hsh[val]
  # end
  # def << val
  #   @hsh[val] += 1; @total += 1 ; self
  # end

  def [] val
    @hsh[val.hash % BUCKET_SIZE]
  end
  def << val
    @hsh[val.hash % BUCKET_SIZE] += 1; @total += 1 ; self
  end

  def insert *words
    words.flatten.each{|word| self << word }
  end
  def clear
    @hsh.clear
    @total = 0
  end

  def stats
    { :total => total,
      :size  => size,
    }
  end
  def size() @hsh.size end

  def full?
    size.to_f / BUCKET_SIZE > 0.5
  end

  def each *args, &block
    @hsh.each(*args, &block)
  end
end
