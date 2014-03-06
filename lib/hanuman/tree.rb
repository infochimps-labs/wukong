require 'tsort'
module Hanuman

  module TreeInstanceMethods
    include TSort

    MultipleRoots = Class.new(TSort::Cyclic)

    def tsort_each_node(&blk)
      stages.keys.each(&blk)
    end

    def tsort_each_child(label, &blk)
      links.select { |link| link.into == label }.map(&:from).each(&blk)
    end

    def directed_sort() self.tsort ; end
    
    def each_stage &blk
      directed_sort.map { |label| stages[label]}.compact.each(&blk)
    end

    def root stage=nil
      return stages[directed_sort.first] unless stage
      return stage unless ancestor(stage)
      self.root(ancestor(stage))
    end

    def ancestor(stage)
      ancestors(stage).first
    end
    
    def leaves
      the_leaves = (descendents - ancestors)
      the_leaves.empty? ? [root] : the_leaves
    end

    def add_link type, from, into
      return if has_link?(from, into)
      raise TSort::Cyclic.new("Cannot link from a stage <#{from.label}> to itself") if into == from
      raise MultipleRoots.new("Cannot link from <#{from.label}> to <#{into.label}> because <#{into.label}> aleady has an ancestor <#{ancestor(into).label}>") if ancestor(into)
      raise TSort::Cyclic.new("Cannot link from leaf <#{from.label}> to the root <#{into.label}>") if into == root && leaves.include?(from)
      super(type, from, into)
    end

    def prepend stage
      add_link(:simple, stage, root)
    end

    def append stage
      leaves.each do |leaf|
        stage_for_leaf       = stage.clone
        stage_for_leaf.label = "#{stage_for_leaf.label}_for_#{leaf.label}".to_sym
        add_link(:simple, leaf, stage_for_leaf)
      end
    end
    
  end
  
  class Tree < Graph
    include TreeInstanceMethods
  end

  class TreeBuilder < GraphBuilder
    include TreeInstanceMethods
  end
end
