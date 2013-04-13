module Hanuman

  module StageInstanceMethods

    attr_accessor :graph
    
    def linkable_name(direction) ; self.label ; end

    def add_link(type, other_stage)
      self.links << Hanuman::LinkFactory.connect(type, linkable_name(:in), other_stage.linkable_name(:out))
      graph.add_link(type, self, other_stage) if graph
    end

    def root
      graph ? graph.root(self) : self
    end

  end
  
  module StageClassMethods

    def label() self.to_s.demodulize.underscore.to_sym ; end
    
    def builder
      return @builder if @builder
      set_builder(StageBuilder.new(label: label))
    end
    
    def set_builder(builder)
      @builder = builder unless builder.nil?
      builder.for_class = self
      @builder
    end
    
    def register(new_label = nil)
      builder.label = new_label || label
      Hanuman::GlobalRegistry.create_or_update(new_label || label, builder)      
      self
    end
  end    

  class Stage
    include Gorillib::Model
    include StageInstanceMethods
    extend  StageClassMethods

    field :label, Symbol, :doc => false
    field :links, Array, :default => []

    def clone
      cloned_attrs = Hash[ attributes.map{ |key, val| dup_key = key.dup rescue key ; dup_val = val.dup rescue val ; [ dup_key, dup_val ] } ]
      cloned_links = links.map{ |link| link.dup }
      self.class.receive(cloned_attrs.merge(links: cloned_links))
    end
  end  
  
  class StageBuilder

    include Gorillib::Model
    include StageInstanceMethods

    field :args,      Hash,  :default => {}
    field :for_class, Class
    field :label,     Symbol
    field :links,     Array, :default => []

    def define(*args, &blk)
      stage = for_class || define_class(label, *args)
      stage.class_eval(&blk) if block_given?
      stage.register
    end

    def build(options = {})      
      for_class.receive self.serialize.merge(options).merge(options[label] || {})
    end
    
    def handle_extra_attributes(attrs)
      args.merge!(attrs)
    end
    
    def merge!(other_builder = {})
      attrs = other_builder.attributes rescue other_builder
      self.receive!(attrs)
      self
    end
    
    def namespace(*args) Hanuman::Stage ; end
 
    def define_class(name, *args)
      klass   = namespace(*args).const_get(name.to_s.camelize, Class.new(namespace(*args))) rescue nil
      klass ||= namespace(*args).const_set(name.to_s.camelize, Class.new(namespace(*args)))
      klass.set_builder(self)
      klass
    end
    
    def serialize()      
      attrs = attributes
      args  = attrs.delete(:args)
      attrs.delete(:links) ; attrs.delete(:for_class)
      attrs.merge(args)
    end

    # This is a hacky method to clone a Stage ; probably could be merged into serialize?
    def clone
      cloned_attrs = Hash[ serialize.map{ |key, val| dup_key = key.dup rescue key ; dup_val = val.dup rescue val ; [ dup_key, dup_val ] } ]
      cloned_links = links.map{ |link| link.dup }
      self.class.receive(cloned_attrs.merge(links: cloned_links).merge(for_class: for_class))
    end

    def into(stage_or_stages)
      if stage_or_stages.is_a?(Array)
        stage_or_stages.each do |other_stage_or_stages|
          while other_stage_or_stages.is_a?(Array)
            other_stage_or_stages = other_stage_or_stages.first
          end
          other_stage = other_stage_or_stages
          self.into(other_stage)
        end
      else
        self.add_link(:simple, stage_or_stages.root)
      end
      stage_or_stages
    end
    alias_method :|, :into
    
  end
end
