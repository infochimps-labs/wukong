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
      builder   = Wukong.registry.retrieve(dataflow)
      dataflow  = builder.build(options)
      @dataflow = dataflow.respond_to?(:stages) ? dataflow.directed_sort.map{ |name| dataflow.stages[name] } : [ dataflow ]
      @dataflow << Wukong.registry.retrieve(:stdout).build
      @source   = Wukong.registry.retrieve(:stdin).build
    end

    def emitter
      @emitter ||= Proc.new do |record, stage|
        next_stage = stage_iterator(stage)
        next_stage.process(record) do |next_record|      
          emitter.call(next_record, next_stage) unless next_record.nil?
        end unless next_stage.nil?      
      end
    end

    def stage_iterator(stage)
      return dataflow.first if stage.nil?
      position = dataflow.find_index(stage)
      dataflow[position + 1]    
    end

    def send_through_processor(record, stage = nil)
      emitter.call(record, stage)
    end
        
    def next_record(&blk)
      trap('SIGINT'){ break }              
      source.process(&blk)
    end
    
    def run!      
      dataflow.each(&:setup)
      next_record do |record|
        send_through_processor(record)
      end
      dataflow.each do |stage|
        stage.finalize do |on_exit|        
          send_through_processor(on_exit, stage) unless on_exit.nil?
        end if stage.respond_to?(:finalize)
        stage.stop
      end
      nil
    end
    
  end
end
