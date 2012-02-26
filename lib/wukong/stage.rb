module Wukong
  module Stage

    class << self
      # gets class for given streamer
      def klass_for(type, handle)
        @@registry[type][handle]
      end

      # returns a new instance of given type
      def make(type, klass, *args, &block)
        klass = klass_for(type, klass) unless klass.is_a?(Class)
        if not klass
          raise "Can't make '#{type}' '#{klass}': registry #{all.inspect}"
        end
        klass.new(*args, &block)
      end

      def has(type, obj)
        all[type].has_value?(obj)
      end

    protected

      # holds registered classes
      @@registry = Hash.new{|h, k| h[k] = {} } unless defined?(@@registry)

      def all
        @@registry
      end

      # adds given streamer to registry
      def register(type, klass)
        @@registry[type][klass.handle] = klass
      end

      def unregister(type, klass)
        @@registry[type].delete(klass.handle)
      end
    end

    class Base
      # stage to receive emitted messages
      attr_reader :next_stage

      # invoked on each record in turn
      # override this in your subclass
      def call(record)
      end

      # passes a record on down the line
      def emit(record, status=nil, headers={})
        if not next_stage then warn("No next_stage set for #{self}") ; return ; end
        next_stage.call(record)
      end

      # called at the end of a run
      def finally
        next_stage.finally if next_stage
      end

      #
      # Graph connections
      #

      def into(stage)
        @next_stage = stage
      end

      def |(stage)
        into(stage)
      end

      def >(stage)
        into(stage)
      end

      #
      # Graph Sugar
      #

      def select(pred=nil, &block)
        self.into(Wukong::Flow.select(pred, &block))
      end

      def reject(pred=nil, &block)
        self.into(Wukong::Flow.reject(pred, &block))
      end

      #
      # Assembly -- find and identify by handle
      #

      def self.handle
        self.to_s.demodulize.underscore.to_sym
      end

      def self.unregister!(type)
        Wukong::Stage.send(:unregister, type, self)
      end
    end

  end
end
