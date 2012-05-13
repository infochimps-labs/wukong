module Hanuman

  class Graph < Stage
    # a retrievable name for this graph
    field      :name,   Symbol
    # the sequence of stages on this graph
    collection :stages, Hanuman::Stage

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
