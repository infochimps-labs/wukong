require 'wukong/widget/many_to_many'
require 'gorillib/enumerable/sum'

#
# An example dataflow -- 
#

Wukong.processor(:delay_buffer) do
  attr_accessor :queue
  field :delay, Integer, position: 0, doc: "number of records to hold in buffer"

  def process(rec)
    queue << rec
    emit(next_item) if ready?
  end

  def next_item
    queue.shift
  end

  # true if there are records at the end of the delay stage
  def ready?
    warn "Hmm, too many records in queue: #{queue}" if queue.size > delay+1
    queue.size > delay
  end

  # resets to an empty state
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

class Wukong::Batcher < Wukong::Processor
  register_action
  include Hanuman::Slottable
  include Hanuman::OutputSlotted

  attr_accessor :queues
  consume :n_1,    Integer, doc: "n-1'th value: the one just emitted"
  consume :tictoc, Integer, doc: "input to drive flow"
  consume :n_2,    Integer, doc: "n-2'nd value: the one before the one just emitted"

  # resets to an empty state, calls super
  def initialize(*)
    super
    @queues = Hash.new{|h,k| h[k] = Array.new } # autovivifying
  end

  def process_input(channel, rec)
    queues[channel] << rec
    emit(next_item) if ready?
  end

  def next_item
    queues.map{|_, queue| queue.shift }
  end

  # true if there is at least one record in each queue
  def ready?
    inslots.values.all?{|inslot| queues[inslot.name].length > 0 }
  end
end

Wukong.chain(:fibbonaci_series) do

  delay_buffer(1, name: :delay)

  batcher(name: :feedback) >
    map(name: :summer, &:sum) >
    many_to_many(name: :fibonacci_n)

  spew(6, item: 0, name: :ticker) > feedback.tictoc

  fibonacci_n          > feedback.n_1
  fibonacci_n          > output
  fibonacci_n > :delay > feedback.n_2
  
  # preload the feedback buffer
  feedback.n_1.process(0)
  feedback.n_2.process(0)
  feedback.n_2.process(1)
end

# Wukong.dataflow(:dump) do
#   stdout << Wukong.dataflow(:fibbonaci_series).out
# end
