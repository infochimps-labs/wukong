module Wukong
  class Source < Hanuman::Action
    include Hanuman::IsOwnOutputSlot
    def self.register_source(name=nil, &block)
      register_action(name, &block)
    end

    def drive
      each do |record|
        output.process(record)
      end
    end

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
      register_source
    end

    class FileSource < Wukong::Source::IO
      field :filename, Pathname, :doc => "Filename to read from"

      def self.make(workflow, filename, stage_name=nil, attrs={})
        super(workflow, attrs.merge(:filename => filename, :name => stage_name))
      end

      def setup
        super
        @file = File.open(filename)
      end

      register_source
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
      register_source :integers
    end
  end
end
