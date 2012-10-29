module Wukong
  class Sink < Hanuman::Action
    include Hanuman::InputSlotted

    def terminates?() true ; end

    class NullSink < Wukong::Sink
      register_action
      #
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
      register_action
      magic :filename, Pathname, :position => 0, :doc => "Filename to write"
      attr_reader :file
      #
      def setup
        super
        filename.dirname.mkpath
        @file = File.open(filename, "w")
      end

      def stop
        @file.close if @file
      end
    end

    # Writes all lines to $stdout
    class Stdout < Wukong::Sink::IO
      register_action
      def file() $stdout ; end
    end

    # Writes all lines to $stderr
    class Stderr < Wukong::Sink::IO
      register_action
      def file() $stderr ; end
    end

    class ArraySink < Wukong::Sink
      register_action
      magic :records, Array, :position => 0, :default => [], :writer => :protected
      #
      def process(record)
        self.records << record
      end
    end
  end
end
