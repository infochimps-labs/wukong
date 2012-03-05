module Wukong
  class Sink
    include Wukong::Stage

    def tell(event, *info)
    end

    def Sink.inherited(subklass)
      Wukong.register_sink(subklass)
    end

    class IO < Wukong::Sink
      attr_reader :file

      def call(record)
        file.puts(record)
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

      def initialize
        @records = []
        super()
      end

      def call(record)
        self.records << record
      end

      def tell(event, *info)
      end

    end
  end
end
