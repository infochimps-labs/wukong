module Hanuman
  class Stage
    include Gorillib::Builder
    alias_method :configure, :receive!

    member     :owner,   Whatever,       :doc => 'the graph this stage sits in'
    magic      :doc,     String,         :doc => 'freeform description of this stage type'

    field      :inputs,  Gorillib::Collection, :doc => 'inputs to this stage',      :default => ->{ Gorillib::Collection.new }
    field      :outputs, Gorillib::Collection, :doc => 'inputs to this stage',      :default => ->{ Gorillib::Collection.new }

    # wire this slot into another slot
    # @param other [Hanuman::Slot] the other stage
    # @returns the other slot
    def >(other)
      _, other = owner.connect(self, :default, other, :default)
      other
    end

    # wire this stage's output into another stage's input
    # @param other [Hanuman::Stage]the other stage
    # @returns this stage, for chaining
    def into(other)
      owner.connect(self, :default, other, :default)
      self
    end

    # wire another slot into this one
    # @param other [Hanuman::Outlinkable] the other stage of slot
    # @returns this object, for chaining
    def <<(other)
      from(other)
      self
    end

    # wire another slot into this one
    # @param other [Hanuman::Outlinkable] the other stage or slot
    # @returns this object, for chaining
    def from(other)
      owner.connect(other, :default, self, :default)
      self
    end

    # @returns the stage, namespaced by the graph that owns it
    def fullname
      [owner.try(:fullname), name].compact.join('.')
    end

    def self.stage_type()  typename.gsub(/.*\W/, '') ; end
    def stage_type()       self.class.stage_type     ; end

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

    # Information about how things are going.
    def report
      self.attributes
    end
  end
end
