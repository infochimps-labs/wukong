module Hanuman

  class Graph < Action
    field      :name,   Symbol, :doc => 'a retrievable name for this graph'
    collection :stages, Hanuman::Stage, :doc => 'the sequence of stages on this graph'
    field :edges,  Hash, :default => {}, :doc => 'connections among all stages on the graph'

    def add_stage(stage)
      stages << stage
      stage.write_attribute(:owner, self)
      stage
    end

    def connect(st_a, st_b)
      edges[st_a.fullname] = st_b.fullname
      st_a.write_attribute(:output, st_b)
      st_b.write_attribute(:input,  st_a)
    end

    # def owner(*args)
    #   super || self
    # end

    def tree(options={})
      super.merge( :stages => stages.to_a.map{|stage| stage.tree(options) } )
    end

    def graph(name, &block)
      stage(name, :_type => Hanuman::Graph, &block)
    end

    def action(name, &block)
      stage(name, :_type => Hanuman::Action, &block)
    end

    def resource(name, &block)
      stage(name, :_type => Hanuman::Resource, &block)
    end

  end
end
