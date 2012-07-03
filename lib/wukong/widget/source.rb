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
      # the enumerable object to delegate
      attr_reader :obj

      def initialize(obj)
        @obj = obj
      end
      def each
        block_given? ? obj.each(Proc.new)  : obj.each
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
      def setup
        super
        @file = $stdin
      end
      register_source
    end

    class FileSource < Wukong::Source::IO
      magic :filename, Pathname, :doc => "Filename to read from"

      def setup
        p [self, self.instance_variable_get('@extra_attributes')]
        super
        @file = File.open(filename)
      end

      register_source
    end

    module CappedGenerator
      extend Gorillib::Concern
      included do
        attr_reader :num
        magic :qty, Integer, :default => 2**63, :doc => "Number of items to generate", :writer => true
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
