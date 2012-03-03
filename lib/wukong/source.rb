module Wukong
  module Source

    class Base < Wukong::Stage
      def run
        each do |record|
          begin
            emit(record)
          rescue StandardError => e
            warn "#{e}\t#{e.backtrace.first}\t#{record}"
            next
          end
        end
      end

      def Base.inherited(subklass)
        Wukong.register_source(subklass)
      end
    end

    class Iter < Wukong::Source::Base
      # the enumerable object to delegate
      attr_reader :obj

      def initialize(obj)
        @obj = obj
        super()
      end
      def each(&block)
        obj.each(&block)
      end
    end

    class IO < Wukong::Source::Base
      attr_reader :file

      def each(&block)
        file.each do |line|
          yield line.chomp
        end
      end
    end

    # emits each line from $stdin
    class Stdin < Wukong::Source::IO
      def file() $stdin ; end
    end

    class Integers < Wukong::Source::Base
      def each
        @num = 0
        loop{ yield @num ; @num += 1 }
      end
    end
  end
end
