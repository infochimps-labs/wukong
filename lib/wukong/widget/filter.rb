module Wukong
  module Widget

    class Filter < Wukong::Processor
      def process(*args) emit(*args) if select?(*args) ; end
      def reject?(*args) not select?(*args) ; end
    end

    class IncludeAll < Filter
      register_processor
      #
      def select?(*args) ; true ; end
    end

    class ExcludeAll < Filter
      register_processor
      #
      def select?(*args) ; false ; end
    end

    # Selects only records matching this regexp
    class RegexpFilter < Filter
      register_processor(:regexp)
      #
      magic :pattern, Regexp, :doc => 'strings matching this regular expression will be selected'
      def select?(str)
        pattern.match(str)
      end
    end

    class NotRegexpFilter < Filter
      register_processor(:not_regexp)
      #
      magic :pattern, Regexp, :doc => 'strings matching this regular expression will be rejected'
      def select?(str)
        not pattern.match(str)
      end
    end

    class Limit < Filter
      register_processor
      #
      magic :max_records, Integer, :doc => 'maximum records to allow', :writer => true
      def select?(*)
        count < max_records
      end
    end

    class Select < Filter
      register_processor

      # @param [Proc] proc becomes body of `select?` method
      # @yield ...or supply a block directly
      def initialize(*args, &block)
        attrs = args.extract_options!
        @blk = block || args.shift || attrs.delete(:blk) or raise "Please supply a proc or a block to #{self.class}.new"
        super(*args, attrs){}
        define_singleton_method(:select?, @blk)
      end
    end

    class Reject < Filter
      register_processor

      # @param [Proc] proc use for body of `reject?` method
      # @yield ...or supply a block directly
      def initialize(*args, &block)
        attrs = args.extract_options!
        @blk = block || args.shift || attrs.delete(:blk) or raise "Please supply a proc or a block to #{self.class}.new"
        super(*args, attrs){}
        define_singleton_method(:reject?, @blk)
      end
      def select?(*args) not reject?(*args) ; end
    end

  end
end
