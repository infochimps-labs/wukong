module Wukong
  @@flows = {} unless defined?(@@flows)

  def self.flow(handle=:global, &block)
    @@flows[handle] ||= Wukong::Flow.new(handle)
    @@flows[handle].instance_eval(&block) if block_given?
    @@flows[handle]
  end

  def self.mapper(flow_name=:mapper, &block)
    flow(flow_name) do
      input = source(:stdin)
      instance_exec(input, &block) | stdout
    end
  end

  def self.reducer(flow_name=:reducer, &block)
    flow(flow_name) do
      input = source(:stdin) | group
      instance_exec(input, &block) | stdout
    end
  end

  VALID_IDENTIFIER_RE = /\A[a-z]\w+\z/i

  def self.streamer(handle, &block)
    raise ArgumentError, "Handle must contain no funny characters" unless (handle.to_s =~ VALID_IDENTIFIER_RE)
    handle     = handle.to_s.underscore.to_sym
    klass_name = handle.to_s.camelize.to_sym
    raise ArgumentError, "Already defined" if Wukong::Streamer.const_defined?(klass_name)
    klass = Class.new(Wukong::Streamer::Base, &block)
    Wukong::Streamer.const_set(klass_name, klass)
    klass
  end

  class Flow
    # a retrievable name for this flow
    attr_reader :handle

    def initialize(handle)
      @handle = handle
    end

    def source(src=nil, *args, &block)
      @source = Wukong.make_source(src, *args, &block) if src
      @source
    end

    def run
      source.tell(:beg_stream)
      source.run
      source.finally
      source.tell(:end_stream)
    end

    [:map, :limit, :group, :monitor, :counter].each do |meth|
      define_method(meth){|*args, &block| Wukong.make_streamer(meth, *args, &block) }
    end

    [:from_json, :to_json, :from_tsv, :to_tsv].each do |meth|
      define_method(meth){|*args, &block| Wukong.make_formatter(meth, *args, &block) }
    end

    def project(*args, &block) Wukong.make_streamer(:proc_streamer, *args, &block) ; end
    def iter(enumerable) ;   Wukong.make_source(:iter, enumerable)    ; end
    def stdin()  @stdin  ||= Wukong.make_source(:iter, $stdin)        ; end
    def stdout() @stdout ||= Wukong.make_sink(  :stdout)              ; end
    def stderr() @stderr ||= Wukong.make_sink(  :stderr)              ; end

    def select(*args, &block) Wukong::Stage.select(*args, &block) ; end
    def reject(*args, &block) Wukong::Stage.reject(*args, &block) ; end

  end
end
