module Hanuman

  class Graph < Stage
    magic      :name,    Symbol,               :position => 0, :doc => 'name of this stage'
    field      :stages,  Gorillib::Collection, :doc => 'the sequence of stages on this graph',      :default => ->{ Gorillib::Collection.new }
    field      :edges,   Hash,                 :doc => 'connections among all stages on the graph', :default => {}

    #
    # Construct stages
    #

    def stage(label, attrs={}, &block)
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
        val = Hanuman::Stage.receive(attrs.merge(owner: self), &block)
        set_stage(label, val)
      end
      val
    end

    def set_stage(label, stage)
      stage.write_attribute(:owner, self)
      stage.write_attribute(:name, label || next_label_for(stage)) unless stage.attribute_set?(:name)
      stages[label] = stage
    end

    def next_label_for(stage)
      :"#{stage.stage_type}_#{stages.size}"
    end

    #
    # Labelled stages
    #

    def lookup(ref)
      ref.is_a?(Symbol) ? stages.fetch(ref) : ref
    end

    def subgraph(label, &block)
      stage(label, :_type => Hanuman::Graph, &block)
    end

    def chain(label, &block)
      stage(label, :_type => Hanuman::Chain, &block)
    end

    def action(label, &block)
      stage(label, :_type => Hanuman::Action, &block)
    end

    def resource(label, &block)
      stage(label, :_type => Hanuman::Resource, &block)
    end

    #
    # Connections among stages
    #

    #
    # * look up the targets (resolving labels to stages, etc)
    #
    def connect(from_stage, into_stage)
      from_stage = lookup(from_stage)
      into_stage = lookup(into_stage)

      from_stage.set_sink(into_stage)
      into_stage.set_source(from_stage)

      edges[from_stage] = into_stage

      [from_stage, into_stage]
    end

    #
    # Control flow
    #

    def setup
      stages.each_value{|stage| stage.setup}
    end

    def stop
      source_stages .each{|stage| stage.stop}
      process_stages.each{|stage| stage.stop}
      sink_stages   .each{|stage| stage.stop}
    end

    def source_stages()  []     ; end
    def process_stages() stages ; end
    def sink_stages()    []     ; end

  end

end

module Hanuman
  class Chain < Graph
    include Hanuman::InputSlotted
    include Hanuman::OutputSlotted
  end
end
