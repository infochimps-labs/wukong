module Wukong

  # A module which can be included by other drivers which lets them
  # use EventMachine under the hood.
  module EventMachineDriver
    
    include DriverMethods

    # :nodoc:
    def self.included klass
      klass.class_eval do
        def self.add_signal_traps
          Signal.trap('INT')  { log.info 'Received SIGINT. Stopping.'  ; EM.stop }
          Signal.trap('TERM') { log.info 'Received SIGTERM. Stopping.' ; EM.stop }                  
        end
      end
    end

    # :nodoc:
    def initialize(label, settings)
      super
      @settings = settings      
      @dataflow = construct_dataflow(label, settings)
    end
    
  end
end
