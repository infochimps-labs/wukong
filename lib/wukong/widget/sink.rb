module Wukong
  class Sink < Hanuman::Stage


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

      def initialize(filename)
        @filename = filename
      end

      def setup
        @file = File.open(filename, "w")
      end

      def stop
        @file.close if @file
      end
    end

    # Writes all lines to $stdout
    class Stdout < Wukong::Sink::IO
      def file() $stdout ; end
    end

    # Writes all lines to $stderr
    class Stderr < Wukong::Sink::IO
      def file() $stderr ; end
    end

    class ArraySink < Wukong::Sink
      attr_reader :records

      def setup
        @records = []
      end

      def process(record)
        self.records << record
      end
    end
  end
end
