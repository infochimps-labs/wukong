module Wukong
  class Transform < Hanuman::Stage

    # override this in your subclass
    def process(record)
    end

    #
    #
    #

    # passes a record on down the line
    def emit(record, status=nil, headers={})
      next_stage.call(record) if next_stage
    end

    # def Transform.inherited(subklass)
    #   Wukong.register_streamer(subklass)
    # end

    #
    # Use a ProcTransform when you want to decide whether to emit
    # (for example, if you'd like to emit more than one record, or to emit an
    # actual nil). Use a map when you want to emit exactly one record out per
    # record in.
    #
    class ProcTransform < Wukong::Transform
      # @param [Proc] proc to delegate for call
      # @yield if proc is omitted, block must be supplied
      def initialize(prc=nil, &block)
        prc ||= block or raise "Please supply a proc or a block to #{self.class}.new"
        define_singleton_method(:call, prc)
      end
    end

    #
    # Evaluates the block and emits the result if non-nil
    #
    class Map < Wukong::Transform
      attr_reader :blk

      # @param [Proc] proc to delegate for call
      # @yield if proc is omitted, block must be supplied
      def initialize(blk=nil, &block)
        @blk = blk || block or raise "Please supply a proc or a block to #{self.class}.new"
      end

      def call(*args)
        result = blk.call(*args)
        emit result unless result.nil?
      end
    end

    class Identity < Wukong::Transform
      def call(record)
        emit(record)
      end
    end

    class Counter < Wukong::Transform
      # Count of records this run
      attr_reader :count

      def initialize
        reset!
      end

      def reset!
        @count = 0
      end

      def beg_group(*args)
        reset!
      end

      def end_group(key)
        emit( [key, count] )
      end

      def call(record)
        @count += 1
      end
    end

    class GroupArrays < Wukong::Transform
      def beg_group
        @records = []
      end

      def end_group(key)
        emit(key, @records)
      end

      def call(record)
        @records << record
      end
    end

    class Limit < Wukong::Transform::Counter
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

    class Group < Wukong::Transform
      def start(key, *vals)
        @key = key
        next_stage.tell(:beg_group, @key)
      end

      def end_group
        next_stage.tell(:end_group, @key)
      end

      def call( (key, *vals) )
        start(key, *vals) unless defined?(@key)
        if key != @key
          end_group
          start(key, *vals)
        end
        emit( [key, *vals] )
      end

      def finally
        end_group
        super()
      end
    end

  end
end
