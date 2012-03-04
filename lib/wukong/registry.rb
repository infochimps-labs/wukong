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
      # def self.source(handle) sources.find(handle) ; end
      define_method("#{type}_klass"){|handle| @@registries[type].find(handle) }
      # def self.register_source(klass) sources.register(klass) ; end
      define_method("register_#{type}"){   |klass|  @@registries[type].register(klass) }
      # def self.unregister_source(handle) sources.register(klass) ; end
      define_method("unregister_#{type}"){ |handle| @@registries[type].unregister(handle) }
      # def self.source_exists?(handle) sources.exists?(handle) ; end
      define_method("#{type}_exists?"){       |handle| @@registries[type].exists?(handle) }
      #
      # def self.create_source(klass, *args, &block) sources.new(*args, &block) ; end
      define_method("create_#{type}"){|*args, &block| @@registries[type].create(*args, &block) }
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
    def find(handle)
      return handle if handle.is_a?(Class)
      self[handle]
    end

    def exists?(handle)
      self.has_key?(handle)
    end

    def create(handle, *args, &block)
      find(handle).new(*args, &block)
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

    # A valid identifier starts with a letter and has only letters, numbers and underscores
    VALID_IDENTIFIER_RE = /\A[a-z]\w+\z/i

    def self.valid_handle?(handle)
      handle.to_s =~ VALID_IDENTIFIER_RE
    end

  end

end
