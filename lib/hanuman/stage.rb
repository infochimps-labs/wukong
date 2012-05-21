module Hanuman
  class Stage
    include Gorillib::Builder
    alias_method :configure, :receive!

    field      :name,    Symbol,         :doc => 'name for this stage; should be unique among other stages on its containing graph', :tester => true
    member     :owner,   Whatever,       :doc => 'the graph this stage sits in'

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

    def lookup(stage)
      owner.lookup(stage)
    end

    #
    # Graph connections
    #

    def notify(msg)
      true
    end

    def report
      self.attributes
    end

    def to_key()      name   ; end
    def key_method() :name ; end
  end
end
