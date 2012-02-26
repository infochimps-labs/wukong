module Wukong
  module Streamer

    class Base < Wukong::Stage::Base
      def initialize
        reset!
        super
      end

      def reset!
      end

      def finally
      end

      def Base.inherited(subklass)
        Wukong::Stage.send(:register, :streamer, subklass)
      end
    end

    class Proxy < Wukong::Streamer::Base
      attr_reader :proc
      def initialize(proc)
        @proc = proc
      end

      def call(*args)
        self.instance_exec(*args, &proc)
      end
    end

    class Identity < Wukong::Streamer::Base
      def call(record)
        emit(record)
      end
    end

    class Counter < Wukong::Streamer::Base
      # Count of records this run
      attr_reader :count

      def reset!
        @count = 0
      end

      def call(record)
        @count += 1
        super(record)
      end
    end

    class Limit < Wukong::Streamer::Counter
      # records seen so far
      attr_reader :max_records

      def initialize(max_records)
        @max_records = max_records
        super()
      end

      def call(record)
        super(record)
        emit(record) unless (count > max_records)
      end
    end

  end

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
