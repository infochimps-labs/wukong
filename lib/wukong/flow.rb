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

      def source(src=nil)
        @source = src if src
        @source
      end

      def make(type, handle, *args, &block)
        Wukong::Stage.make(type, handle, *args, &block)
      end

      def limit(num) ; make(:streamer, limit, num) ; end
      def stdin()  @stdin  ||= make(:source, :stdin) ; end
      def stdout() @stdout ||= make(:sink,  :stdout)  ; end
      def stderr() @stderr ||= make(:sink,  :stderr)  ; end
    end

    class Simple < Wukong::Flow::Base
    end
  end
end
