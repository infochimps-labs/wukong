module Wukong
  @@registries ||= Hash.new

  def self.registry(type, base_klass=Object, options={})
    type = type.to_sym
    plural = options[:plural] || "#{type}s"
    return if @@registries[type]
    @@registries[type] = Registry.new(base_klass)
    self.singleton_class.class_eval do
      # def self.sources() @sources ; end
      define_method(plural){ @@registries[type] }
      # def self.source(handle) sources.get(handle) ; end
      define_method("#{type}_klass"){|handle| @@registries[type].get(handle) }
      # def self.register_source(klass) sources.register(klass) ; end
      define_method("register_#{type}"){   |klass|  @@registries[type].register(klass) }
      # def self.unregister_source(handle) sources.register(klass) ; end
      define_method("unregister_#{type}"){ |handle| @@registries[type].unregister(handle) }
      # def self.has_source?(handle) sources.has?(handle) ; end
      define_method("has_#{type}?"){       |handle| @@registries[type].has?(handle) }
      #
      # def self.make_source(klass, *args, &block) sources.new(*args, &block) ; end
      define_method("make_#{type}"){|*args, &block| @@registries[type].make(*args, &block) }
    end
  end

  class Registry < Mash
    def initialize(base_klass)
      super(){|h, k| h[k] = self.class.new }
      @base_klass = base_klass
    end

    def all
      self.dup.freeze
    end

    # given example of registry's class, return it;
    # otherwise, look up the handle and return that.
    def get(handle)
      return handle if handle.is_a?(Class)
      self[handle]
    end

    def has?(handle)
      self.has_key?(handle)
    end

    def make(handle, *args, &block)
      get(handle).new(*args, &block)
    end

    # add given class to registry
    def register(klass)
      self[klass.handle] = klass
    end

    def unregister(klass)
      self.delete(klass.handle)
    end

    def convert_key(key)
      key.is_a?(Class) ? key.handle : super(key)
    end

  end

end
