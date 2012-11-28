module Wukong  
  class Driver

    class << self
      def run(dataflow, options)
        new(dataflow, options).run!
      end
    end

    def lookup(label)
      builder = Wukong.registry.retrieve(label)
      builder.build(@settings)
    end
    
    def wire(flow)
      using = @settings[:wiring] || :emitter
      if flow.complete?
        flow.links.each do |link| 
          Hanuman::LinkFactory.connect(using, flow.stages[link.from], flow.stages[link.into])
        end
      end
      flow
    end
  end
  
  class LocalDriver < Driver
    attr_accessor :dataflow, :source
    
    def initialize(dataflow, options = {})
      builder    = (Wukong.registry.retrieve(dataflow) or raise Error.new("No such processor or dataflow: #{dataflow.inspect}"))
      dataflow   = builder.build(options)
      @dataflow  = dataflow.respond_to?(:stages) ? dataflow.directed_sort.map{ |name| dataflow.stages[name] } : [ dataflow ]
      @dataflow << Wukong.registry.retrieve(:stdout).build
      @source    = Wukong.registry.retrieve(:stdin).build
    end

    def emitter
      @emitter ||= ProcEmitter.new(dataflow)
    end

    def stage_iterator(stage)
      return dataflow.first if stage.nil?
      position = dataflow.find_index(stage)
      dataflow[position + 1]    
    end

    def next_record(&blk)
      trap('SIGINT'){ break }              
      source.process(&blk)
    end

    def run!      
      dataflow.each(&:setup)
      next_record do |record|
        emitter.send_through_dataflow(record)
      end
      dataflow.each do |stage|
        stage.finalize(&emitter.advance(stage)) if stage.respond_to?(:finalize)
        stage.stop
      end
      nil
    end
  end
end

class ProcEmitter

  attr_accessor :dataflow

  def initialize(dataflow)
    @dataflow = dataflow
  end

  def to_proc
    return @wiring if @wiring
    @wiring = Proc.new do |stage, record|
      stage.process(record, &advance(stage)) if stage          
    end
  end

  def send_through_dataflow(record)
    self.call(dataflow.first, record)
  end
  
  def advance(stage)
    next_stage = stage_iterator(stage)
    self.to_proc.curry.call(next_stage)
  end

  def stage_iterator(stage)
    position = dataflow.find_index(stage)
    dataflow[position + 1]    
  end 

  def call(*args)
    to_proc.call(*args)
  end
  
end
