module Wukong

  module Sink

    class Base < Wukong::Stage
      def Base.inherited(subklass)
        Wukong::Stage.send(:register, :sink, subklass)
      end
    end

    class IO < Wukong::Sink::Base
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

    class ArrayCapture < Wukong::Sink::Base
      attr_reader :records

      def initialize
        @records = []
        super()
      end

      def call(record)
        self.records << record
      end
    end
  end
end
