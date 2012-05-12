module Wukong

  @@flows = {} unless defined?(@@flows)

  def self.flow(handle=:global, &block)
    @@flows[handle] ||= Wukong::Flow.new(handle)
    @@flows[handle].instance_eval(&block) if block_given?
    @@flows[handle]
  end

  def self.streamer(handle, &block)
    raise ArgumentError, "Handle must contain no funny characters" unless Wukong::Registry.valid_handle?(handle)
    handle     = handle.to_s.underscore.to_sym
    klass_name = handle.to_s.camelize.to_sym
    raise ArgumentError, "Already defined" if Wukong::Streamer.const_defined?(klass_name)
    klass = Class.new(Wukong::Streamer, &block)
    Wukong::Streamer.const_set(klass_name, klass)
    klass
  end

  class Flow < Wukong::Graph

    [:map, :limit, :group, :monitor, :counter].each do |meth|
      define_method(meth){|*args, &block| add_stage(:streamer, meth, *args, &block) }
    end

    [:from_json, :to_json, :from_tsv, :to_tsv].each do |meth|
      define_method(meth){|*args, &block| add_stage(:formatter, meth, *args, &block) }
    end

    def project(*args, &block) add_stage(:streamer, :proc_streamer, *args, &block) ; end
    def iter(enumerable) ;   add_stage(:source, :iter, enumerable)    ; end
    def stdin()  @stdin  ||= add_stage(:source, :iter, $stdin)        ; end
    def stdout() @stdout ||= add_stage(:sink,   :stdout)              ; end
    def stderr() @stderr ||= add_stage(:sink,   :stderr)              ; end

    def select(*args, &block) Wukong::Stage.select(*args, &block) ; end
    def reject(*args, &block) Wukong::Stage.reject(*args, &block) ; end

  end
end
