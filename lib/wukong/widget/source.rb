module Wukong
  class Source < Hanuman::Action
    def self.register_source(name=nil, &block)
      register_action(name, &block)
    end

    def drive
      each do |record|
        @output.process(record)
      end
    end

    # def setup
    #   # GC::Profiler.enable
    # end
    # def periodically(count)
    #   # GC.enable ; GC.start ; GC.disable
    #   # $stderr.puts GC::Profiler.result
    # end
    # def stop
    #   # GC::Profiler.disable
    # end

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
          line.chomp!
          yield line
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

      def self.make(workflow, filename, stage_name=nil, attrs={})
        super(workflow, attrs.merge(:filename => filename, :name => stage_name))
      end

      def setup
        super
        @file = File.open(filename)
      end

      register_source
    end

    module CappedGenerator
      extend Gorillib::Concern
      included do
        attr_reader :num
        magic :size, Integer, :default => 2**63, :doc => "Number of items to generate", :writer => true
      end

      def setup
        super
        @num = 0
      end

      def max
        size
      end

      def next_item
      end

      def each
        loop do
          break if @num > max
          yield next_item
          @num += 1
        end
      end
    end

    class Integers < Wukong::Source
      register_source :integers
      include CappedGenerator
      magic :init, Integer, :default => 0, :doc => "Initial offset", :writer => true

      def max
        init + size - 1
      end

      def next_item
        @num
      end

      def self.make(dataflow, size=nil, attrs={})
        attrs[:size] = size if not size.nil?
        super(dataflow, attrs)
      end
    end

  end
end
