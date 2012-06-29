module Hanuman

  class Graph < Action
    field      :stages, Gorillib::Collection, :doc => 'the sequence of stages on this graph',      :default => ->{ Gorillib::Collection.new }
    field      :edges,  Hash,                 :doc => 'connections among all stages on the graph', :default => {}

    # * defines the named input slot, if it doesn't exist
    # * wires the given stage to that input slot
    # * returns the named input slot
    def input(slot_name)  ; inputs[slot_name] ; end

    def output(slot_name) ; outputs[slot_name] ; end

    def set_input(slot_name, stage)
      inputs[slot_name] = stage
    end
    def set_output(slot_name, stage)
      outputs[slot_name] = stage
    end

    def next_label_for(stage)
      :"#{stage.stage_type}_#{stages.size}"
    end

    def set_stage(label, stage)
      stages[label] = stage
    end

    def stage(label, attrs=nil, &block)
      if attrs.is_a?(Hanuman::Stage)
        # actual object: assign it into collection
        val = attrs
        set_stage(label, val)
      elsif stages.include?(label)
        # existing item: retrieve it, updating as directed
        val = stages.fetch(label)
        val.receive!(attrs, &block)
      else
        # missing item: autovivify item and add to collection
        # { key_method => item_key, :owner => self }
        val = Hanuman::Stage.receive(attrs, &block)
        set_stage(label, val)
      end
      val
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
