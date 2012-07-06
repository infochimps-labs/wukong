require 'wukong/widget/many_to_many'

Wukong.processor(:delay_buffer) do
  register_action
  attr_accessor :queue
  field :delay, Integer, position: 0, doc: "number of records to hold in buffer"

  def process(rec)
    queue << rec
    emit(queue.shift) if ready?
  end

  # true if there are records at the end of the delay stage
  def ready?
    warn "Hmm, too many records in queue: #{queue}" if queue.size > delay+1
    queue.size > delay
  end

  # resets to an empty state, calls super
  def setup(*)
    super
    @queue = Array.new
  end

  # emits all remaining elements of the queue
  def stop
    queue.each{|rec| emit(rec) }
    super
  end
end

class Wukong::Yes < Wukong::Source
  register_action
  include Wukong::Source::CappedGenerator
  field :item, Whatever, position: 1, doc: "An item to emit over and over and over"

  def next_item
    item
  end
end

Wukong.processor(:sum) do
  register_action
  field :total, Integer, writer: false, default: 0, doc: 'running total of input values'
  def setup(*)
    super
    @total = 0
  end
  def process(num)
    @total += num
    emit(@total)
  end
end

class Wukong::Zipper < Wukong::Processor
  register_action
  attr_accessor :queues
  field :delay, Integer, position: 0, doc: "number of records to hold in buffer"

  # resets to an empty state, calls super
  def setup(*)
    super
    @queues = Hash.new{|h,k| h[k] = Array.new } # autovivifying
  end

  def process_input(topic, rec)
    queues[topic] << rec
    emit(queues.map{|_, queue| queue.shift }) if ready?
  end

  # true if there is at least one record in each queue
  def ready?
    queues.all?{|_,queue| queue.length > 0 }
  end
end

Wukong.dataflow(:series) do

  ones = yes(10, 1)
  m2m  = many_to_many

  ones > m2m

  m2m > map{|x| x + 100 } > stdout
  m2m > sum > delay_buffer(3) > stdout





  # input > stage(:splitty, stratify) do
  #   output(:low) > file('users_med')
  # end
  # stage(:splitty).output(:med) > file('users_med')
  # stage(:splitty).output(:hi)  > file('users_hi')
  #
  # # or
  #
  # splitty = stratify
  # input > splitty do
  #   output(:low) > file('users_med')
  # end
  # splitty.output(:med) > file('users_med')
  # splitty.output(:hi)  > file('users_hi')

end
