module Wukong
  class Source < Hanuman::Action

    def source?() true ; end

    class << self ; alias_method :register_source, :register_action ; end

    def drive
      each do |record|
        sink.process(record)
      end
    end

    class Iter < Source
      register_source
      # the enumerable object to delegate
      magic :obj, Whatever, :position => 0
      def each(&block)
        obj.each(&block)
      end
    end

    class IO < Source
      attr_reader :file

      def each
        file.each do |line|
          line.chomp!
          yield line if block_given?
        end
      end

      def stop
        file.close if file
      end
    end

    # emits each line from $stdin
    class Stdin < Wukong::Source::IO
      register_source
      def setup
        super
        @file = $stdin
      end
    end

    class FileSource < Wukong::Source::IO
      register_source
      magic :filename, Pathname, :position => 0, :doc => "Filename to read from"

      def setup
        super
        @file = File.open(filename)
      end
    end

    module CappedGenerator
      extend Gorillib::Concern
      included do
        attr_reader :num
        magic :qty, Integer, :position => 0, :default => 5, :doc => "Number of items to generate", :writer => true
      end

      def setup(*)
        super
        @num = 0
      end

      def next_item
      end

      def each
        (1..2**63).each do
          break if @num >= qty
          yield next_item
          @num += 1
        end
      end
    end

    class Integers < Wukong::Source
      register_source :integers
      include CappedGenerator

      def next_item
        @num
      end
    end

  end
end
