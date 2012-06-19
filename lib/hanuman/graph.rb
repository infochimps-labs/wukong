module Hanuman
  class Graph < Action
    # collection :stages, Hanuman::Stage, :doc => 'the sequence of stages on this graph'
    # field      :edges,  Hash,           :doc => 'connections among all stages on the graph', :default => {}
    include Hanuman::IsOwnInputSlot
    include Hanuman::IsOwnOutputSlot

    def initialize() @stages = {} ; end
    def stages()     @stages.dup  ; end
    
    def determine_fullname(stage)
      [self.fullname, @stages.invert[stage]].map(&:to_s).join('.')
    end

    def set_stage(name, stage)
      stage.write_attribute(:name, name)
      stage.write_attribute(:owner, self)
      @stages[name.to_sym] = stage
      stage
    end

    # def next_name_for(stage, basename=nil)
    #   "#{basename || stage.class.handle}_#{stages.size}"
    # end

    # def connect(from_slot, into_slot)
    #   from_slot = lookup(from_slot)
    #   into_slot = lookup(into_slot)
    #   actual_from_slot = from_slot.set_output(into_slot)
    #   actual_into_slot = into_slot.set_input( from_slot)
    #   #
    #   edges[actual_from_slot] = actual_into_slot
    #   [from_slot, into_slot]
    # end

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
