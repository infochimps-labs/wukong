module Wukong
  @@flows = {} unless defined?(@@flows)

  def self.flow(handle=:global, &block)
    @@flows[handle] ||= Wukong::Flow::Simple.new(handle)
    @@flows[handle].instance_eval(&block) if block_given?
    @@flows[handle]
  end

  module Flow

    class Base
      # a retrievable name for this flow
      attr_reader :handle

      def initialize(handle)
        @handle = handle
      end

      def source(src=nil, *args, &block)
        @source = make(:source, src, *args, &block) if src
        @source
      end

      def run
        source.run
      end

      def make(type, src, *args, &block)
        if src.respond_to?(:each) && (! src.respond_to?(:emit))
          args.unshift(src) ; src = :proxy
        end
        Wukong::Stage.make(type, src, *args, &block)
      end

      def map(&block)
        make(:streamer, :proxy, block)
      end

      def select(*args, &block) Wukong::Stage::Base.select(*args, &block) ; end
      def reject(*args, &block) Wukong::Stage::Base.reject(*args, &block) ; end

      def limit(num) ; make(:streamer, :limit, num) ; end
      def stdin()  @stdin  ||= make(:source, :proxy, $stdin ) ; end
      def stdout() @stdout ||= make(:sink,   :stdout) ; end
      def stderr() @stderr ||= make(:sink,   :stderr) ; end
    end

    class Simple < Wukong::Flow::Base
    end
  end
end
