module Wukong
  module EventMachineDriver
    include DriverMethods

    def self.included klass
      klass.class_eval do
        def self.add_signal_traps
          Signal.trap('INT')  { log.info 'Received SIGINT. Stopping.'  ; EM.stop }
          Signal.trap('TERM') { log.info 'Received SIGTERM. Stopping.' ; EM.stop }                  
        end
      end
    end
      
  end
end
