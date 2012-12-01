module Wukong
  module SpecHelpers
    class SpecDriver < Array

      attr_reader :processor

      def initialize processor
        super()
        @processor = processor
      end
      
      def run
        return false unless processor
        processor.given_records.each do |input|
          processor.process(input) do |output|
            self << output
          end
        end
        processor.finalize do |output|
          self << output
        end
        processor.stop
        self
      end

    end
  end
end
