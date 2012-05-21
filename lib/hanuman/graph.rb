module Hanuman

  class Action < Stage
    def self.register_action(meth_name=nil, &block)
      meth_name ||= handle ; klass = self
      Hanuman::Graph.send(:define_method, meth_name) do |*args, &block|
        begin
          klass.make(workflow=self, *args, &block)
        rescue StandardError => err ; err.polish("adding #{meth_name} to #{self.name} on #{args}") rescue nil ; raise ; end
      end
    end

    def self.make(workflow, *args, &block)
      stage = new(*args)
      workflow.add_stage stage
      stage.receive!(&block)
      stage
    end
  end

  class Resource < Stage
    has_input
    has_output
    field :schema, Gorillib::Factory, :default => ->{ Whatever }
  end

  class Graph < Action
    collection :stages, Hanuman::Stage, :doc => 'the sequence of stages on this graph'
    field      :edges,  Hash,           :doc => 'connections among all stages on the graph', :default => {}
    has_input
    has_output

    def next_name_for(stage, basename=nil)
      "#{basename || stage.class.handle}_#{stages.size}"
    end

    def add_stage(stage)
      stage.write_attribute(:name, next_name_for(stage)) if not stage.name?
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
