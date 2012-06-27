module Hanuman

  class Graph < Action
    # collection :stages, Hanuman::Stage, :doc => 'the sequence of stages on this graph'
    field      :stages, Gorillib::Collection, :doc => 'the sequence of stages on this graph',      :default => ->{ Gorillib::Collection.new }
    field      :edges,  Hash,                 :doc => 'connections among all stages on the graph', :default => {}

    def next_label_for(stage)
      "#{stage.stage_type}_#{stages.size}"
    end

    def stage(label, stg=nil)
      if stg
        stg = Hanuman::Stage.receive(stg)
        set_stage(stg, label)
      else
        stages.fetch(label)
      end
    end

    def set_stage(stg, label=nil)
      label ||= (stg.read_attribute(:name) || next_label_for(stg))
      # stg.write_attribute(:owner, self)
      stages[label] = stg
      p [stages, label, stg]
      stg
    end

    def connect(from_stage, from_slot, into_stage, into_slot)
      from_stage = lookup(from_stage)
      into_stage = lookup(into_stage)

      from_stage.set_output(from_slot, into_stage)
      into_stage.set_input( into_slot, from_stage)

      # actual_from_slot = from_slot.set_output(into_slot)
      # actual_into_slot = into_slot.set_input( from_slot)
      # edges[actual_from_slot] = actual_into_slot
      [from_stage, into_stage]
    end

    def lookup(ref)
      ref.is_a?(Symbol) ? action(ref) : ref
    end

    def graph(label, &block)
      stage(label, :_type => Hanuman::Graph, &block)
    end

    def action(label, &block)
      stage(label, :_type => Hanuman::Action, &block)
    end

    def resource(label, &block)
      stage(label, :_type => Hanuman::Resource, &block)
    end
  end

end
