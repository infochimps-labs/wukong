module Wukong
  module SpecHelpers
    class SpecDriver < Array
      
      include Wukong::DriverMethods
      
      def initialize *args
        super()
        if args.size == 1
          self.dataflow = args.first
        else
          self.dataflow, _ = construct_dataflow(args[0], args[1])
        end
        setup_dataflow
      end

      def process output
        self << output
      end
      
      def run
        return false unless dataflow
        dataflow.given_records.each do |input|
          driver.send_through_dataflow(input)
        end
        finalize_and_stop_dataflow
        self
      end

    end
  end
end
