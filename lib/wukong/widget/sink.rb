module Wukong
  class Sink < Processor
    
    class Stdout < Sink
      def process(record)
        $stdout.puts record
      end
      register
    end
    
  end
end
