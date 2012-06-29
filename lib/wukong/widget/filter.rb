module Wukong
  module Widget

    class Filter < Wukong::Processor
      def process(*args) emit(*args) if select?(*args) ; end
      def reject?(*args) not select?(*args) ; end
    end

    class IncludeAll < Filter
      def select?(*args) ; true ; end
      register_processor
    end

    class ExcludeAll < Filter
      def select?(*args) ; false ; end
      register_processor
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
      register_processor(:regexp)
    end

    class NotRegexpFilter < Filter
      magic :pattern, Regexp, :doc => 'strings matching this regular expression will be rejected'
      def select?(str)
        not pattern.match(str)
      end

      def self.make(workflow, pattern, attrs={}, &block)
        super workflow, attrs.merge(:pattern => pattern), &block
      end
      register_processor(:not_regexp)
    end

    class Select < Filter
      # @param [Proc] proc becomes body of `select?` method
      # @yield ...or supply a block directly
      def initialize(attrs={}, &block)
        @blk = attrs[:block] || block or raise "Please supply a proc or a block to #{self.class}.new"
        define_singleton_method(:select?, @blk)
      end

      def self.make(workflow, blk=nil, attrs={}, &block)
        blk ||= block
        super workflow, attrs.merge(:block => blk)
      end
      register_processor
    end

    class Reject < Filter
      # @param [Proc] proc use for body of `reject?` method
      # @yield ...or supply a block directly
      def initialize(attrs={}, &block)
        @blk = attrs[:block] || block or raise "Please supply a proc or a block to #{self.class}.new"
        define_singleton_method(:reject?, @blk)
      end
      def select?(*args) not reject?(*args) ; end

      def self.make(workflow, blk=nil, attrs={}, &block)
        blk ||= block
        super workflow, attrs.merge(:block => blk)
      end
      register_processor
    end

    class Limit < Filter
      include CountingProcessor
      magic :max_records, Integer, :doc => 'maximum records to allow', :writer => true

      def select?(*)
        count < max_records
      end

      def self.make(workflow, max, attrs={}, &block)
        super workflow, attrs.merge(:max_records => max), &block
      end
      register_processor
    end

  end
end
