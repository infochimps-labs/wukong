module Wukong
  module Streamer
    class Base

      # Options, initially set from the command-line args -- see
      # Script#process_argv!
      attr_accessor :options

      #
      # Accepts option hash from script runner
      #
      def initialize options={}
        self.options = options
      end

      #
      # Pass each record to +#process+
      #
      def stream
        $stdin.each do |line|
          record = recordize(line.chomp)
          next unless record
          process(*record) do |output_record|
            emit output_record
          end
        end
      end

      #
      # Default recordizer: returns array of fields by splitting at tabs
      #
      def recordize line
        line.split("\t")
      end

      def emit record
        puts record.to_flat.join("\t")
      end

      #
      # Process each record in turn, yielding the records to emit
      #
      def process *args, &block
        raise "override the process method in your implementation: it should process each record."
      end

      #
      # To track processing errors inline,
      # pass the line back to bad_record!
      #
      def bad_record! key, *args
        warn "Bad record #{args.inspect[0..400]}"
        puts ["bad_record-"+key, *args].join("\t")
      end
    end
  end
end
