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

    class Base
      def accept?(*args)
        true
      end

      def call(*args)
        emit(*args) if accept?(*args)
      end
    end

    class None < Wukong::Filter::Base
      def accept?(*args)
        false
      end
    end

    class All < Wukong::Filter::Base
      def accept?(*args)
        true
      end
    end

  end

end
