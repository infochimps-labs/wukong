module Hanuman
  class Stage
    include Gorillib::Builder

    field      :name,    Symbol,         :doc => 'name for this stage; should be unique among other stages on its containing graph', :tester => true
    member     :input,   Hanuman::Stage, :doc => 'stage(s) in graph that feed into this one', :default => ->{ Hanuman::Stage.new(:name => "#{self.name}:input") }
    member     :output,  Hanuman::Stage, :doc => 'stage(s) in graph this one feeds into'
    member     :owner,   Hanuman::Stage, :doc => 'the graph this stage sits in'
    field      :doc,     String,         :doc => 'briefly documents this stage and its purpose'

    # @returns the stage, namespaced by the graph that owns it
    def fullname
      [owner.try(:fullname), name].compact.join('.')
    end

    def self.handle
      Gorillib::Inflector.underscore(Gorillib::Inflector.demodulize(self.name))
    end

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

    # wire this stage's output into another stage's input
    # @param stage [Hanuman::Stage]the other stage
    # @returns the stage itself
    def into(stage)
      owner.connect(self, stage)
      self
    end

    # wire another stage's output into this stage's input
    # @param stage [Hanuman::Stage]the other stage
    # @returns the stage itself
    def <<(stage)
      from(stage)
      self
    end

    # wire another stage's output into this stage's input
    # @param stage [Hanuman::Stage]the other stage
    # @returns the stage itself
    def from(stage)
      owner.connect(stage, self)
      self
    end

    def notify(msg)
      true
    end

    def tree(options={})
      { :name => name,
        :input => input.name,
      }
    end

    def report(options={})
      tree(options)
    end

  end

  class Action < Stage
    # field :consumes, Hash, :of => Gorillib::Factory, :default => ->{ {:input  => Whatever} }
    # field :produces, Hash, :of => Gorillib::Factory, :default => ->{ {:output => Whatever} }
  end

  class Resource < Stage
    field :schema, Gorillib::Factory, :default => ->{ Whatever }
  end
end
