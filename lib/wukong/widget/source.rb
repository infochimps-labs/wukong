module Wukong
  class Source < Hanuman::Stage

    class Iter < Source
      # the enumerable object to delegate
      attr_reader :obj

      def initialize(obj)
        @obj = obj
      end
      def each(&block)
        obj.each(&block)
      end
    end

    class IO < Source
      attr_reader :file

      def each(&block)
        file.each do |line|
          yield line.chomp
        end
      end

      def stop
        file.close if file
      end
    end

    # emits each line from $stdin
    class Stdin < Wukong::Source::IO
      def setup
        super
        @file = $stdin
      end
    end

    class FileSource < Wukong::Source::IO
      attr_reader :filename
      def initialize(filename)
        @filename = filename
      end

      def setup
        super
        @file = File.open(filename)
      end
    end

    class Integers < Wukong::Source
      attr_reader :num
      field :min,  Integer, :default => 0
      field :max,  Integer, :default => nil
      field :step, Integer, :default => 1

      def setup
        super
        @num = 0
      end

      def each
        loop do
          break if max.present? && (num >= max)
          yield num
          @num += step
        end
      end
    end
  end
end
