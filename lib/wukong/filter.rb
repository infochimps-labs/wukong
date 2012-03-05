module Wukong

  class Filter  < Wukong::Stage
    def accept?(*args)
      true
    end

    def call(*args)
      emit(*args) if accept?(*args)
    end

    module Invert
      def accept?(*args)
        not super
      end
    end

    class All < Wukong::Filter
      def accept?(*args)
        true
      end
    end

    class None < Wukong::Filter
      def accept?(*args)
        false
      end
    end

    class ProcFilter < Wukong::Filter
      # @param [Proc] proc to delegate for call
      # @yield if proc is omitted, block must be supplied
      def initialize(prc=nil, &block)
        prc ||= block or raise "Please supply a proc or a block to #{self.class}.new"
        define_singleton_method(:accept?, prc)
      end
    end

    class ProcRejecter < Wukong::Filter::ProcFilter
      # @param [Proc] proc to delegate for call
      # @yield if proc is omitted, block must be supplied
      def initialize(prc=nil, &block)
        prc ||= block or raise "Please supply a proc or a block to #{self.class}.new"
        define_singleton_method(:reject?, prc)
      end

      def accept?(*args)
        not reject?(*args)
      end
    end

    class RegexpFilter < Wukong::Filter
      attr_reader :re
      def initialize(re)
        @re = re
      end

      def accept?(*args)
        re.match(*args)
      end
    end

    class RegexpRejecter < Wukong::Filter::RegexpFilter
      include Wukong::Filter::Invert
    end

  end
end
