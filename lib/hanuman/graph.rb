module Hanuman

  class Graph < Action
    collection :stages, Hanuman::Stage, :doc => 'the sequence of stages on this graph'
    field      :edges,  Hash,           :doc => 'connections among all stages on the graph', :default => {}

    member     :input,   Hanuman::Stage, :doc => 'stage(s) in graph that feed into this one', :default => ->{ Hanuman::Stage.new(:name => "#{self.name}:input") }
    member     :output,  Hanuman::Stage, :doc => 'stage(s) in graph this one feeds into'

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
      stage.write_attribute(:owner, self)
      stages << stage
      stage
    end

    def add_edge(st_a, st_b, a_out_slot, b_in_slot)
      a_slot_name = "#{st_a.fullname}[#{a_out_slot}]"
      b_slot_name = "[#{b_in_slot}]#{st_b.fullname}"
      edges[a_slot_name] = b_slot_name
    end

    def connect(st_a, st_b, a_out_slot=nil, b_in_slot=nil)
      a_out_slot ||= :_ ; b_in_slot ||= :_
      add_edge(st_a, st_b, a_out_slot, b_in_slot)
      st_a.set_output a_out_slot, st_b
      st_b.set_input  b_in_slot,  st_a
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


    def self.register_action(name, klass=nil, &meth_body)
      name = name.to_sym
      raise ArgumentError, 'Supply either a class or a block, not both' if (klass && meth_body) || (!klass && !meth_body)
      if block_given?
        define_method(name) do |*args, &blk|
          add_stage meth_body.call(*args, &blk)
        end
      else
        define_method(name) do |*args, &blk|
          add_stage klass.new(*args, &blk)
        end
      end
    end

  end
end
