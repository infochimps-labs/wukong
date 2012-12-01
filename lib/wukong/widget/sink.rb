module Wukong
  class Sink < Processor
    
    class Stdout < Sink
      def process(record)
        begin
          $stdout.puts record
        rescue Errno::EPIPE => e
          exit(2)
        end
      end
      register
    end
    
  end
end
