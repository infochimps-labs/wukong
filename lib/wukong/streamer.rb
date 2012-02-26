module Wukong
  module Streamer

    class Base < Wukong::Stage::Base
      def initialize
        reset!
        super
      end

      def reset!
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

    class Group < Wukong::Streamer::Base
      def initialize
      end

      def start(key, *vals)
        @key = key
        @records = []
      end

      def end_group
        emit(@records)
      end

      def call( (key, *vals) )
        start(key, *vals) unless defined?(@key)
        if key != @key
          end_group
          start(key, *vals)
        end
        @records << key
      end

      def finally
        end_group
        super()
      end
    end

  end

end
