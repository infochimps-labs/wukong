module Wukong
  class Sink < Wukong::Processor

    def sink?()   true ; end

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
      magic :filename, Pathname, :doc => "Filename to write"
      attr_reader :file

      def setup
        super
        filename.dirname.mkpath
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
      magic :records, Array, :default => [], :writer => :protected

      def process(record)
        self.records << record
      end
    end
  end
end
