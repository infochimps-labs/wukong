module Wukong
  module Local

    # A class for driving processors over the STDIN/STDOUT protocol.
    class StdioDriver < EM::P::LineAndTextProtocol
      
      include DriverMethods
      include Processor::StdoutProcessor
      include Logging

      # :nodoc:
      def initialize(label, settings)
        super
        construct_dataflow(label, settings)
      end
      
      def self.add_signal_traps
        Signal.trap('INT')  { log.info 'Received SIGINT. Stopping.'  ; EM.stop }
        Signal.trap('TERM') { log.info 'Received SIGTERM. Stopping.' ; EM.stop }                  
      end
      
      def self.start(label, settings = {})
        EM.attach($stdin, self, label, settings)
      end

      def post_init      
        self.class.add_signal_traps
        setup_dataflow
      end

      def receive_line line
        send_through_dataflow(line)
      rescue => e
        error = Wukong::Error.new(e)
        EM.stop
        
        # We'd to *raise* `error` here and have it be handled by
        # Wukong::Runner.run but we are fighting with EventMachine.
        # It seems no matter what we do, EventMachine will swallow any
        # Exception raised here (including SystemExit) and exit the
        # Ruby process with a return code of 0.
        #
        # Instead we just log the message that *would* have gotten
        # logged by Wukong::Runner.run and leave it to EventMachine to
        # exit very unnaturally.
        log.error(error.message)
      end

      def unbind
        finalize_and_stop_dataflow
        EM.stop
      end
    end
  end
end
