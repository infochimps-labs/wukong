require_relative('event_machine_driver')
module Wukong
  module Local

    # A class for driving processors over the STDIN/STDOUT protocol.
    class StdioDriver < EM::P::LineAndTextProtocol
      include EventMachineDriver
      include Processor::StdoutProcessor
      include Logging
      
      def self.start(label, settings = {})
        EM.attach($stdin, self, label, settings)
      end

      def post_init      
        self.class.add_signal_traps
        setup_dataflow
      end

      def receive_line line
        driver.send_through_dataflow(line)
      rescue => e
        EM.stop
        raise Wukong::Error.new(e)
      end

      def unbind
        finalize_and_stop_dataflow
        EM.stop
      end
    end
  end
end
