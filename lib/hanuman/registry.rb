module Hanuman
  class Registry

    REGISTRY = {} unless defined? REGISTRY
    
    def create_or_update(label, builder)
      create(label, builder) ? true : update(label, builder)
    end

    def create(label, builder)
      return false if registered?(label)
      REGISTRY[label] = builder
      true
    end
    
    def update(label, new_definition)
      return false unless registered?(label)
      REGISTRY[label].merge!(new_definition)
      true
    end

    def registered?(label)
      REGISTRY.keys.include? label
    end

    def retrieve(label)
      REGISTRY[label].clone rescue nil
    end
    
    def decorate_with_registry(graph_instance)
      REGISTRY.each_pair do |label, definition|
        graph_instance.define_singleton_method(label) do |*args, &blk|
          builder = Hanuman::GlobalRegistry.retrieve(label)
          builder = handle_dsl_arguments_for(builder, *args, &blk)
          stages[builder.label] = builder
        end
      end
    end
    
    def show()   REGISTRY.dup   ; end
    
    def clear!() REGISTRY.clear ; end

  end  
  
  GlobalRegistry = Registry.new unless defined? GlobalRegistry
end
