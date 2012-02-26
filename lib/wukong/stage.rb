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

      def call(record)
      end

      def emit(record, status=nil, headers={})
        if not next_stage then warn("No next_stage set for #{self}") ; return ; end
        next_stage.call(record)
      end

      def into(stage)
        @next_stage = stage
      end

      def |(stage)
        into(stage)
      end

      #
      # Graph Sugar
      #

      def self.select(pred=nil, &block)
        case
        when Wukong::Stage.has(:filter, pred) then pred
        when pred.respond_to?(:match)  then Wukong::Filter::RegexpFilter.new(pred)
        when pred.is_a?(Proc)          then Wukong::Filter::ProcFilter.new(pred)
        when pred.nil? && block_given? then Wukong::Filter::ProcFilter.new(block)
        else raise "Can't make a filter from #{pred.inspect}"
        end
      end
      def select(pred=nil, &block)
        self.into(self.class.select(pred, &block))
      end

      def self.reject(pred=nil, &block)
        case
        when Wukong::Stage.has(:filter, pred) then pred
        when pred.respond_to?(:match)  then Wukong::Filter::RegexpRejecter.new(pred)
        when pred.is_a?(Proc)          then Wukong::Filter::ProcRejecter.new(pred)
        when pred.nil? && block_given? then Wukong::Filter::ProcRejecter.new(block)
        else raise "Can't make a filter from #{pred.inspect}"
        end
      end
      def reject(pred=nil, &block)
        self.into(self.class.reject(pred, &block))
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
