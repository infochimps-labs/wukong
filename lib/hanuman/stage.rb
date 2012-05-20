module Hanuman
  class Stage
    include Gorillib::Builder
    alias_method :configure, :receive!

    field      :name,    Symbol,         :doc => 'name for this stage; should be unique among other stages on its containing graph', :present => true
    member     :owner,   Whatever,       :doc => 'the graph this stage sits in'
    field      :doc,     String,         :doc => 'briefly documents this stage and its purpose'

    # @returns the stage, namespaced by the graph that owns it
    def fullname
      [owner.try(:fullname), name].compact.join('.')
    end

    def self.handle
      Gorillib::Inflector.underscore(Gorillib::Inflector.demodulize(self.name))
    end

    def to_key() name ; end

    #
    # Methods
    #

    # Called after the graph is constructed, before the flow is run
    def setup
    end

    # Called to signal the flow should stop. Close any open connections, flush
    # buffers, stop supervised projects, etc.
    def stop
    end

    #
    # Graph connections
    #

    # wire this stage's output into another stage's input
    # @param stage [Hanuman::Stage]the other stage
    # @returns the other stage`
    def >(stage)
      into(stage)
      stage
    end

    # wire another stage's output into this stage's input
    # @param stage [Hanuman::Stage]the other stage
    # @returns the stage itself
    def <<(stage)
      from(stage)
      self
    end

    # wire this stage's output into another stage's input
    # @param stage [Hanuman::Stage]the other stage
    # @returns the stage itself
    def into(other, my_out_slot=nil, other_in_slot=nil)
      owner.connect(self, other, my_out_slot, other_in_slot)
      self
    end

    # wire another stage's output into this stage's input
    # @param stage [Hanuman::Stage]the other stage
    # @returns the stage itself
    def from(other, other_out_slot=nil, my_in_slot=nil)
      owner.connect(other, self, other_out_slot, my_in_slot)
      self
    end

    def notify(msg)
      true
    end

    def report
      self.attributes
    end

  end

  class Action < Stage
    collection :inputs,  Hanuman::Stage
    collection :outputs, Hanuman::Stage

    def set_input(name, stage)
      set_collection_item(:inputs, name, stage)
    end
    def set_output(name, stage)
      set_collection_item(:outputs, name, stage)
    end

    def input(name=nil)
      raise ArgumentError, "Stages have only one input" unless input_name.nil? || input_name.to_s == '_'
      get_collection_item(:inputs, name)
    end
    def output(name=nil)
      raise ArgumentError, "Stages have only one output" unless output_name.nil? || output_name.to_s == '_'
      get_collection_item(:outputs, name)
    end
  end

  class Resource < Stage
    field :schema, Gorillib::Factory, :default => ->{ Whatever }
    collection :inputs,  Hanuman::Stage
    collection :outputs, Hanuman::Stage

    def set_input(name, stage)
      set_collection_item(:inputs, name, stage)
    end
    def set_output(name, stage)
      set_collection_item(:outputs, name, stage)
    end

  end
end
