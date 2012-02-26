module Wukong

  module Filter

    class Base < Wukong::Stage::Base
      def accept?(*args)
        true
      end

      def call(*args)
        emit(*args) if accept?(*args)
      end
    end

    module Invert
      def accept?(*args)
        not super
      end
    end

    class All < Wukong::Filter::Base
      def accept?(*args)
        true
      end
    end

    class None < Wukong::Filter::Base
      def accept?(*args)
        false
      end
    end

    class ProcFilter < Wukong::Filter::Base
      # evaluated on each record to decide whether to filter
      attr_reader :proc

      def initialize(proc)
        @proc = proc
      end

      def accept?(*args)
        proc.call(*args)
      end
    end

    class ProcRejecter < Wukong::Filter::ProcFilter
      def accept?(*args)
        not super
      end
    end

    class RegexpFilter < Wukong::Filter::Base
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
