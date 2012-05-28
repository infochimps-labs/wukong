module Wukong
  class Sink < Wukong::Processor

    class NullSink < Wukong::Sink
      def process(record)
        true # do nothing
      end
    end

    # Write all lines to given file
    class IO < Wukong::Sink
      def process(record)
        file.puts(record)
      end
    end

    class FileSink < Wukong::Sink::IO
      attr_reader :filename
      attr_reader :file

      def initialize(filename)
        @filename = filename
      end

      def setup
        super
        @file = File.open(filename, "w")
      end

      def stop
        @file.close if @file
      end

      register_processor
    end

    # Writes all lines to $stdout
    class Stdout < Wukong::Sink::IO
      def file() $stdout ; end
      register_processor
    end

    # Writes all lines to $stderr
    class Stderr < Wukong::Sink::IO
      def file() $stderr ; end
      register_processor
    end

    class ArraySink < Wukong::Sink
      field :records, Array, :default => [], :writer => :protected

      def process(record)
        self.records << record
      end
    end
  end
end
