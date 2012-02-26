module Wukong
  module Source

    class Base < Wukong::Stage::Base
      def run
        each do |record|
          emit(record)
        end
      end

      def Base.inherited(subklass)
        Wukong::Stage.send(:register, :source, subklass)
      end
    end

    class Demo < Wukong::Source::Base
      def each(&block)
        (1 .. 100).each(&block)
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
