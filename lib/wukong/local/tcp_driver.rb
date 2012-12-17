require_relative('event_machine_driver')
module Wukong
  module Local
    
    # A class for driving processors over a TCP protocol.
    class TCPDriver < EM::P::LineAndTextProtocol
      include EventMachineDriver
      include Processor::BufferedProcessor
      include Logging

      def self.start(label, settings = {})
        host = settings[:host] || Socket.gethostname
        port = settings[:port] || 9000
        EM.start_server(host, port, self, label, settings)
        log.info "Server started on #{host} on port #{port}"
        add_signal_traps
      end

      def post_init
        port, ip = Socket.unpack_sockaddr_in(get_peername)
        log.info "Connected to #{ip} on #{port}"
        setup_dataflow
      end

      def receive_line line
        @buffer = []      
        operation = proc { driver.send_through_dataflow(line) }
        callback  = proc { flush_buffer @buffer }
        EM.defer(operation, callback)
      rescue => e
        EM.stop
        raise Wukong::Error.new(e)
      end

      def flush_buffer records
        send_data(records.join("\n") + "\n")
        records.clear
      end

      def unbind
        EM.stop
      end
      
    end
  end
end
