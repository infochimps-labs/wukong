module Wukong
  module Source

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

    module ClassMethods
    end
    def self.included(base)
      base.send(:include, Wukong::Stage)
      base.extend(ClassMethods)
      Wukong.register_source(base)
      def base.inherited(subklass) Wukong.register_source(subklass) ; end
    end
  end

  module Source
    class Iter
      include Wukong::Source
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

    class IO
      include Wukong::Source
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

    class Integers
      include Wukong::Source
      def each
        @num = 0
        loop{ yield @num ; @num += 1 }
      end
    end
  end
end
