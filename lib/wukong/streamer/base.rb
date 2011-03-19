module Wukong
  module Streamer
    class Base

      # Options, initially set from the command-line args -- see
      # Script#process_argv!
      attr_reader :own_options

      #
      # Accepts option hash from script runner
      #
      def initialize options={}
        @own_options = options
      end

      def options
        Settings.deep_merge own_options
      end

      #
      # Pass each record to +#process+
      #
      def stream
        Log.info("Streaming on:\t%s" % [Script.input_file]) unless Script.input_file.blank?
        before_stream
        each_record do |line|
          record = recordize(line.chomp) or next
          process(*record) do |output_record|
            emit output_record
          end
          track(record)
        end
        after_stream
      end

      def track record
        monitor.periodically(record.to_s[0..1000])
      end

      def each_record &block
        $stdin.each(&block)
      end

      # Called exactly once, before streaming begins
      def before_stream
      end

      # Called exactly once, after streaming completes
      def after_stream
      end

      #
      # Default recordizer: returns array of fields by splitting at tabs
      #
      def recordize line
        line.split("\t") rescue nil
      end

      #
      # Serializes the record to output.
      #
      # Emits a single line of tab-separated fields created by calling #to_flat
      # on the record and joining with "\t".
      #
      # Does no escaping or processing of the record -- that's to_flat's job, or
      # yours if you override this method.
      #
      def emit record
        puts record.to_flat.join("\t")
      end

      #
      # Process each record in turn, yielding the records to emit
      #
      def process *args, &block
      end

      #
      # To track processing errors inline,
      # pass the line back to bad_record!
      #
      def bad_record! key, *args
        warn "Bad record #{args.inspect[0..400]}"
        puts ["bad_record-"+key, *args].join("\t")
      end

      # A periodic logger to track progress
      def monitor
        @monitor ||= PeriodicMonitor.new
      end

      # Defines a process method on the fly to execute the given mapper.
      #
      # This is still experimental.
      # Among other limitations, you can't use ++yield++ -- you have to call
      # emit() directly.
      def mapper &mapper_block
        @mapper_block = mapper_block.to_proc
        self.instance_eval do
          def process *args, &block
            instance_exec(*args, &@mapper_block)
          end
        end
        self
      end

      # Creates a new object of this class and injects the given block
      # as the process method
      def self.mapper *args, &block
        self.new.mapper(*args, &block)
      end

      # Delegates back to Wukong to run this instance as a mapper
      def run options={}
        Wukong.run(self, nil, options)
      end

      # Creates a new object of this class and runs it
      def self.run options={}
        Wukong.run(self.new, nil, options)
      end

    end
  end
end
