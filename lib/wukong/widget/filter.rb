module Wukong
  module Widget

    class Filter < Wukong::Processor
      def process(*args) emit(*args) if     accept?(*args) ; end
      def reject?(*args) not accept?(*args) ; end
    end

    class Rejecter < Filter
      def process(*args) emit(*args) if not reject?(*args) ; end
      def accept?(*args) not reject?(*args) ; end
      def reject?(*args) true ; end
    end

    class All < Filter
      def accept?(*args) ; true ; end
    end

    class None < Rejecter
      def reject?(*args) ; true ; end
    end

    class Limit < Rejecter
      field :max_records, Integer, :doc => 'maximum records to allow'
      field :count,       Integer, :doc => 'count of records this run'

      def setup
        self.count = 0
      end

      def reject?
        count >= max_records
      end

      def process(record)
        super(record)
        count += 1
        flow.tell(:halt) if reject?(record)
      end
    end

    class ProcFilter < Filter
      # @param [Proc] proc use for body of `reject?` method
      # @yield ...or supply a block directly
      def initialize(prc=nil, &block)
        prc ||= block or raise "Please supply a proc or a block to #{self.class}.new"
        define_singleton_method(:accept?, prc)
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

    # Accepts only records matching this regexp
    class RegexpFilter < Filter
      field :re, Regexp, :doc => 'strings matching this regular expression will be accepted'
      def initialize(re)
        @re = re
      end
      def accept?(str)
        re.match(str)
      end
    end

    class RegexpRejecter < RegexpFilter
      field :re, Regexp, :doc => 'strings matching this regular expression will be rejected'
      def initialize(re)
        @re = re
      end
      def accept?(str)
        re.match(str)
      end
    end

  end
end
