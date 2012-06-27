module Wukong
  module Widget

    class Filter < Wukong::Processor
      def process(*args) emit(*args) if select?(*args) ; end
      def reject?(*args) not select?(*args) ; end
    end

    class Rejecter < Filter
      def process(*args) emit(*args) if not reject?(*args) ; end
      def select?(*args) not reject?(*args) ; end
      def reject?(*args) true ; end
    end

    class All < Filter
      def select?(*args) ; true ; end
    end

    class None < Rejecter
      def reject?(*args) ; true ; end
    end

    # Selects only records matching this regexp
    class RegexpFilter < Filter
      magic :pattern, Regexp, :doc => 'strings matching this regular expression will be selected'
      def select?(str)
        pattern.match(str)
      end

      def self.make(workflow, pattern, attrs={}, &block)
        super workflow, attrs.merge(:pattern => pattern), &block
      end
      register_processor(:re)
    end

    class RegexpRejecter < Rejecter
      magic :pattern, Regexp, :doc => 'strings matching this regular expression will be rejected'
      def reject?(str)
        pattern.match(str)
      end

      def self.make(workflow, pattern, attrs={}, &block)
        super workflow, attrs.merge(:pattern => pattern), &block
      end
      register_processor(:not_re)
    end

    class ProcFilter < Filter
      # @param [Proc] proc use for body of `reject?` method
      # @yield ...or supply a block directly
      def initialize(prc=nil, &block)
        prc ||= block or raise "Please supply a proc or a block to #{self.class}.new"
        define_singleton_method(:select?, prc)
      end
    end

    class ProcRejecter < Rejecter
      # @param [Proc] proc use for body of `reject?` method
      # @yield ...or supply a block directly
      def initialize(prc=nil, &block)
        prc ||= block or raise "Please supply a proc or a block to #{self.class}.new"
        define_singleton_method(:reject?, prc)
      end
    end

    class Limit < Rejecter
      include CountingProcessor
      magic :max_records, Integer, :doc => 'maximum records to allow', :writer => true

      def reject?(*)
        count >= max_records
      end

      def self.make(workflow, max, attrs={}, &block)
        super workflow, attrs.merge(:max_records => max), &block
      end
      register_processor
    end

  end
end
