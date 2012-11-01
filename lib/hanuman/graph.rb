module Hanuman
  class Graph < Stage
    include TSort

    field :stages, Hash,  :default => {}
    field :links,  Array, :default => []
    
    def tsort_each_node(&blk)
      stages.keys.each(&blk)
    end

    def tsort_each_child(node, &blk)
      links.select{ |link| link.into == node }.map(&:from).each(&blk)
    end

    def directed_sort() self.tsort ; end
  end

  class GraphBuilder < StageBuilder
    include TSort

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
      stages = attrs.delete(:stages).inject({}){ |hsh, (name, builder)| hsh[name] = builder.build(options) ; hsh }
      for_class.receive attrs.merge(stages: stages)
    end

    def namespace() Hanuman::Graph ; end

    def handle_dsl_arguments_for(stage, *args, &blk)
      options = args.extract_options!
      stage.merge!(options)
      stage
    end

    def extract_links!
      stages.each_pair{ |name, builder| links << builder.links }
      links.flatten!
    end
    
    def serialize
      attrs = attributes
      args  = attrs.delete(:args)
      attrs.delete(:for_class)
      attrs.merge(args)      
    end

    def tsort_each_node(&blk)
      stages.keys.each(&blk)
    end

    def tsort_each_child(node, &blk)
      links.select{ |link| link.into == node }.map(&:from).each(&blk)
    end

    def directed_sort() self.tsort ; end

    def clone
      cloned_attrs  = Hash[ serialize.select{ |key, val| key != :stages }.map{ |key, val| dup_key = key.dup rescue key ; dup_val = val.dup rescue val ; [ dup_key, dup_val ] } ]
      cloned_links  = links.map{ |link| link.dup }
      cloned_stages = Hash[ stages.map{ |stage| stage.clone } ]
      self.class.receive(cloned_attrs.merge(links: cloned_links).merge(stages: cloned_stages).merge(for_class: for_class))
    end
  end
end
