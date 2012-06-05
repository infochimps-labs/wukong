module Hanuman

  class Graph < Action
    collection :stages, Hanuman::Stage, :doc => 'the sequence of stages on this graph'
    field      :edges,  Hash,           :doc => 'connections among all stages on the graph', :default => {}
    include Hanuman::IsOwnInputSlot
    include Hanuman::IsOwnOutputSlot

    def next_name_for(stage, basename=nil)
      "#{basename || stage.class.handle}_#{stages.size}"
    end

    def add_stage(stage)
      stage.write_attribute(:name, next_name_for(stage)) if stage.name.nil?
      stage.write_attribute(:owner, self)
      stages << stage
      stage
    end

    def connect(from_slot, into_slot)
      from_slot = lookup(from_slot)
      into_slot = lookup(into_slot)
      actual_from_slot = from_slot.set_output(into_slot)
      actual_into_slot = into_slot.set_input( from_slot)
      #
      edges[actual_from_slot] = actual_into_slot
      [from_slot, into_slot]
    end

    def lookup(ref)
      ref.is_a?(Symbol) ? resource(ref) : ref
    end

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
