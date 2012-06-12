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

    def new_string_event string
      metadata_hash = Hash.new
      string.define_singleton_method(:_metadata) do
        metadata_hash
      end
      string
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

    module CappedGenerator
      extend Gorillib::Concern
      included do
        attr_reader :num
        field :size, Integer, :default => 2**63, :doc => "Number of items to generate", :writer => true
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
      field :init, Integer, :default => 0, :doc => "Initial offset", :writer => true

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
