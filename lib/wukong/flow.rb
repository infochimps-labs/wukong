module Wukong
  @@flows = {} unless defined?(@@flows)

  def self.flow(handle=:global, &block)
    @@flows[handle] ||= Wukong::Flow::Simple.new(handle)
    @@flows[handle].instance_eval(&block) if block_given?
    @@flows[handle]
  end

  module Flow
    def self.make(type, src, *args, &block)
      if src.respond_to?(:each) && (! src.respond_to?(:emit))
        args.unshift(src) ; src = :proxy
      end
      Wukong::Stage.make(type, src, *args, &block)
    end

    def self.map(&block)
      make(:streamer, :proxy, block)
    end

    def self.select(pred=nil, &block)
      case
      when Wukong::Stage.has(:filter, pred) then pred
      when pred.respond_to?(:match)  then Wukong::Filter::RegexpFilter.new(pred)
      when pred.is_a?(Proc)          then Wukong::Filter::ProcFilter.new(pred)
      when pred.nil? && block_given? then Wukong::Filter::ProcFilter.new(block)
      else raise "Can't make a filter from #{pred.inspect}"
      end
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
        source.finally
      end

      def make(*args, &block)   Wukong::Flow.make(*args, &block) ; end

      def map(&block)           Wukong::Flow.map(&block) ; end
      def select(*args, &block) Wukong::Flow.select(*args, &block) ; end
      def reject(*args, &block) Wukong::Flow.reject(*args, &block) ; end

      def limit(num) ; make(:streamer, :limit, num) ; end


      [:from_json, :to_json, :from_tsv, :to_tsv].each do |meth|
        define_method(meth){|*args| make(:formatter, *args) }
      end

      def stdin()  @stdin  ||= make(:source, :proxy, $stdin ) ; end
      def stdout() @stdout ||= make(:sink,   :stdout) ; end
      def stderr() @stderr ||= make(:sink,   :stderr) ; end
    end

    class Simple < Wukong::Flow::Base
    end
  end
end
