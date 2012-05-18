module Hanuman

  class Graph < Action
    collection :stages, Hanuman::Stage, :doc => 'the sequence of stages on this graph'
    field      :edges,  Hash,           :doc => 'connections among all stages on the graph', :default => {}

    def initialize(*)
      @stage_count = 0
      super
    end

    def next_name_for(stage)
      @stage_count += 1
      "#{stage.class.handle}_#{@stage_count - 1}"
    end

    def add_stage(stage)
      stage.write_attribute(:name, next_name_for(stage)) if not stage.name?
      stages << stage
      stage.write_attribute(:owner, self)
      stage
    end

    def add_edge(st_a, st_b, a_out_slot, b_in_slot)
      a_slot_name = "#{st_a.fullname}:#{a_out_slot}"
      b_slot_name = "#{st_b.fullname}:#{b_in_slot}"
      edges[a_slot_name] = b_slot_name
    end

    def connect(st_a, st_b, a_out_slot=:o, b_in_slot=:i)
      add_edge(st_a, st_b, a_out_slot, b_in_slot)
      # st_a.set_output_slot(st_b, a_out_slot, b_in_slot)
      # st_b.set_input_slot( st_a, a_out_slot, b_in_slot)
      st_a.write_attribute(:output, st_b)
      st_b.write_attribute(:input,  st_a)
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
