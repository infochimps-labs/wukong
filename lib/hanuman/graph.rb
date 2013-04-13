module Hanuman

  module GraphInstanceMethods
    def each_stage &block
      stages.values.each(&block)
    end

    def descendents stage=nil
      links.find_all do |link|
        stage ? link.from == stage.label : true
      end.map(&:into).uniq.map { |label| stages[label] }.compact
    end

    def ancestors stage=nil
      links.find_all do |link|
        stage ? link.into == stage.label : true
      end.map(&:from).uniq.map { |label| stages[label] }.compact
    end

    def add_stage stage
      stages[stage.label] = stage
    end

    def has_link? from, into
      links.detect { |link| link.from == from.label && link.into == into.label } ? true : false
    end

    def add_link type, from, into
      add_stage(from)
      add_stage(into)
      self.links << Hanuman::LinkFactory.connect(type, from.linkable_name(:in), into.linkable_name(:out))
    end
  end

  class Graph < Stage
    include GraphInstanceMethods
    
    field :stages, Hash,  :default => {}
    field :links,  Array, :default => []
  end

  class GraphBuilder < StageBuilder

    include GraphInstanceMethods
    
    field :stages, Hash,  :default => {}
    field :links,  Array, :default => []

    def define(&blk)     
      graph = for_class || define_class(label) 
      self.instance_eval(&blk) if block_given?
      extract_links!
      graph.register
    end

    def build(options = {})
      attrs  = serialize
      stages = attrs.delete(:stages).inject({}){ |hsh, (name, builder)| hsh[name] = builder.build(stage_specific_options(name, options)) ; hsh }
      for_class.receive attrs.merge(stages: stages)
    end

    def stage_specific_options(stage, options)
      scope = options.delete(stage) || {}
      options.merge(scope)
    end

    def namespace() Hanuman::Graph ; end

    def handle_dsl_arguments_for(stage, *args, &blk)
      options = args.extract_options!
      stage.merge!(options)
      stage
    end

    def extract_links!
      self.links.replace([])
      stages.each_pair{ |name, builder| links << builder.links }
      links.flatten!
    end
    
    def serialize
      attrs = attributes
      args  = attrs.delete(:args)
      attrs.delete(:for_class)
      attrs.merge(args)      
    end

    def clone
      cloned_attrs  = Hash[ serialize.select{ |key, val| key != :stages }.map{ |key, val| dup_key = key.dup rescue key ; dup_val = val.dup rescue val ; [ dup_key, dup_val ] } ]
      cloned_links  = links.map{ |link| link.dup }
      cloned_stages = Hash[ stages.map{ |stage| stage.clone } ]
      self.class.receive(cloned_attrs.merge(links: cloned_links).merge(stages: cloned_stages).merge(for_class: for_class))
    end

  end
    
end
