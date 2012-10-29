module Wukong  
  class Runner

    Configuration = Configliere::Param.new.use(:commandline) unless defined? Configuration
    
    class << self
      def run(label)        
        new(Configuration.resolve!).run(label)
      end
    end
    
    def initialize(settings = {})
      @settings = settings
    end

    def lookup(label)
      return label if label.respond_to?(:run)
      builder = Hanuman::GlobalRegistry.retrieve(label)
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
    
    def run(label)
      flow  = lookup(label)
      wired = wire(flow)
      wired.setup
      wired.run
      wired.stop
    end
    
  end  
  
  class LocalRunner < Runner
    
    def lookup(label)
      Wukong.dataflow(:local){ stdin > send(label) > stdout }
      flow = Wukong.registry.retrieve(:local)
      flow.build(@settings)
    end

  end
end
