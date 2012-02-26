module Wukong
  module Stage

    class << self
      # holds registered classes
      @@registry = Hash.new{|h, k| h[k] = {} } unless defined?(@@registry)
      # adds given streamer to registry
      def register(type, klass)
        @@registry[type][klass.handle] = klass
      end

      # gets class for given streamer
      def klass_for(type, handle) @@registry[type][handle] ; end
      # returns a new instance of given type
      def make(type, handle, *args, &block)
        klass_for(type, handle).new(*args, &block)
      end
    protected :register
    end

    class Base
      # stage to receive emitted messages
      attr_reader :next_stage

      def call(record)
      end

      def emit(record, status=nil, headers={})
        if not next_stage then warn("No next_stage set for #{self}") ; return ; end
        next_stage.call(record)
      end

      def into(stage)
        p [self, @next_stage, stage]
        @next_stage = stage
      end

      def self.handle
        self.to_s.demodulize.underscore.to_sym
      end
    end

  end
end
