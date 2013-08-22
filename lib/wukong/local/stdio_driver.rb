module Wukong
  module Local

    # A class for driving processors over the STDIN/STDOUT protocol.
    #
    # Relies on EventMachine's [LineAndTextProtocol](http://eventmachine.rubyforge.org/EventMachine/Protocols/LineText2.html).
    class StdioDriver < EM::P::LineAndTextProtocol
      
      include DriverMethods
      include Logging

      #
      # == Startup == 
      #

      # Start a new StdioDriver.
      #
      # @param [Symbol] the name of the processor or dataflow to drive
      # @param [Configliere::Param] settings the settings to use
      def self.start(label, settings = {})
        EM.attach($stdin, self, label, settings)
      end

      # :nodoc:
      def initialize(label, settings)
        super
        construct_dataflow(label, settings)
      end

      # Ensures that $stdout is synced.
      def setup()
        $stdout.sync
      end

      # Adds signal traps for SIGINT and SIGTERM to Ensure we capture
      # C-c and friends, stop the EventMachine reactor, &c.
      def self.add_signal_traps
        Signal.trap('INT')  { log.info 'Received SIGINT. Stopping.'  ; EM.stop }
        Signal.trap('TERM') { log.info 'Received SIGTERM. Stopping.' ; EM.stop }
      end

      # Called by EventMachine framework after successfully attaching
      # to $stdin.
      #
      # Adds signal handlers and calls the #setup_dataflow method.
      def post_init      
        self.class.add_signal_traps
        setup_dataflow
      end
      
      #
      # == Reading Input == 
      #
      
      # Called by EventMachine framework after successfully reading a
      # line from $stdin.
      #
      # @param [String] line
      def receive_line line
        send_through_dataflow(line)
      rescue => e
        error = Wukong::Error.new(e)
        # EM.stop
        
        # We'd like to *raise* `error` here and have it be handled by
        # Wukong::Runner.run but we are fighting with EventMachine.run
        # which executes in the middle.
        #
        # It seems no matter what we do, EventMachine.run will swallow
        # any Exception raised here (including SystemExit) and exit
        # the Ruby process with a return code of 0.
        #
        # Instead we just log the message that *would* have gotten
        # logged by Wukong::Runner.run and leave it to EventMachine to
        # exit very unnaturally.
        log.error(error.message)
      end

      #
      # == Handling Output == 
      #
      
      # Writes a record to $stdout.
      #
      # @param [#to_s] record
      def process(record)
        $stdout.puts record
      end

      #
      # == Shutdown == 
      #

      # Called by EventMachine framework after EOF from $stdin.
      #
      # Calls #finalize_and_stop_dataflow method and stops the
      # EventMachine reactor.
      def unbind
        finalize_and_stop_dataflow
        EM.stop
      end
    end
  end
end
