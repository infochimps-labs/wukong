require 'wukong/widget/many_to_many'
require 'gorillib/enumerable/sum'

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
  include Hanuman::OutputSlotted

  attr_accessor :queues
  field :delay, Integer, position: 0, doc: "number of records to hold in buffer"

  field :tictoc,  Hanuman::InputSlot, default: ->{ Hanuman::InputSlot.new(self, 'tictoc') }, doc: "input to drive flow"
  field :input_a, Hanuman::InputSlot, default: ->{ Hanuman::InputSlot.new(self, 'input_a') }
  field :input_b, Hanuman::InputSlot, default: ->{ Hanuman::InputSlot.new(self, 'input_b') }

  # resets to an empty state, calls super
  def setup(*)
    super
    @queues = Hash.new{|h,k| h[k] = Array.new } # autovivifying
    @queues[:tictoc]
    @queues[:input_a]
    @queues[:input_b]
  end

  def process_input(topic, rec)
    queues[topic] << rec
    # p [topic, rec, ready?, queues.map{|k,q| q.length } ]
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
  zzz  = zipper(name: 'zipper join')

  ones > zzz.tictoc

  zzz > map(name: 'summer'){|arr| arr[1..-1].compact.sum } > m2m

  m2m                   > zzz.input_a
  m2m > delay_buffer(1) > zzz.input_b

  m2m > map{|x| x.inspect } > stdout

  setup

  # FIXME: cheating
  zzz.input_a.process(1)
  zzz.input_b.process(1)
  zzz.input_b.process(1)



end

require 'hanuman/graphvizzer/gv_presenter'
basename = Pathname.path_to(:tmp, 'complex_dataflow')
Wukong.to_graphviz.save(basename, 'png')
puts File.read("#{basename}.dot")
