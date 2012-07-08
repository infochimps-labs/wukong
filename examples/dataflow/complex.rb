require 'wukong/widget/many_to_many'
require 'gorillib/enumerable/sum'

Wukong.processor(:delay_buffer) do
  register_action
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

class Wukong::Spew < Wukong::Source
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

class Wukong::Batcher < Wukong::Processor
  register_action
  include Hanuman::MultiInputs
  include Hanuman::OutputSlotted

  attr_accessor :queues
  field :delay, Integer, position: 0, doc: "number of records to hold in buffer"

  consume :n_1, Integer, doc: "n-1'th value: the one just emitted"
  consume :n_2, Integer, doc: "n-2'nd value: the one before the one just emitted"
  consume :tictoc,  Integer, doc: "input to drive flow"

  # resets to an empty state, calls super
  def initialize(*)
    super
    @queues = Hash.new{|h,k| h[k] = Array.new } # autovivifying
  end

  def process_input(topic, rec)
    queues[topic] << rec
    emit(next_item) if ready?
  end

  def next_item
    queues.map{|_, queue| queue.shift }
  end

  # true if there is at least one record in each queue
  def ready?
    input_names.all?{|qname| queues[qname].length > 0 }
  end

  def input_names
    [:n_1, :tictoc, :n_2]
  end


  def to_graphviz(gv)
    gv.node(self.graph_id,
      :label    => name,
      :shape    => draw_shape,
      :inslots  => input_names,
      )
  end

end

Hanuman::Graph.class_eval do
  include Hanuman::MultiInputs

end

Wukong.dataflow(:fibbonaci_series) do
  delay_buffer(1, name: :delay)

  batcher(name: :feedback)  >
    map(name: :summer, &:sum) >
    many_to_many(name: :fibonacci_n)

  spew(4, item: 0, name: :ticker) > feedback.tictoc

  fibonacci_n > :delay > feedback.n_2
  fibonacci_n          > feedback.n_1

  produce(:out, Integer)

  # outslot = Hanuman::OutputSlot.new(stage: self, name: :out)
  # define_singleton_method(:out){ outslot }
  fibonacci_n         > out

  # preload the feedback buffer
  feedback.n_1.process(0)
  feedback.n_2.process(0)
  feedback.n_2.process(1)
end

Wukong.dataflow(:dump) do
  stdout << Wukong.dataflow(:fibbonaci_series).out
end


require 'hanuman/graphvizzer/gv_presenter'
basename = Pathname.path_to(:tmp, 'complex_dataflow')
Wukong.to_graphviz.save(basename, 'png')
puts File.read("#{basename}.dot")
