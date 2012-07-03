module Hanuman

  class Stage
    include Gorillib::Builder
    alias_method :configure, :receive!

    magic      :name,    String,         :doc => 'name of this stage'
    member     :owner,   Whatever,       :doc => 'the graph this stage sits in'
    magic      :doc,     String,         :doc => 'freeform description of this stage type'

    self.ignored_positional_args += [:name, :owner, :doc, :inputs, :outputs, :sink, :source, :consumes, :produces]

    # field      :inputs,  Gorillib::Collection, :of => Hanuman::Stage, :doc => 'inputs to this stage',  :default => ->{ Gorillib::Collection.new }
    # field      :outputs, Gorillib::Collection, :of => Hanuman::Stage, :doc => 'outputs of this stage', :default => ->{ Gorillib::Collection.new }
    #
    #
    # def source(label) inputs[label].stage  ; end
    # def sink(  label) outputs[label].stage ; end
    #
    # def input( label) inputs[label] ; end
    # def output(label) inputs[label] ; end
    #
    # # wire this slot into another slot
    # # @param other [Hanuman::Slot] the other stage
    # # @returns the other slot
    # def >(other)
    #   _, other = owner.connect(self, other)
    #   other
    # end
    #
    # # wire this stage's output into another stage's input
    # # @param other [Hanuman::Stage]the other stage
    # # @returns this stage, for chaining
    # def into(other)
    #   owner.connect(self, other)
    #   self
    # end
    #
    # # wire another slot into this one
    # # @param other [Hanuman::Outlinkable] the other stage of slot
    # # @returns this object, for chaining
    # def <<(other)
    #   from(other)
    #   self
    # end
    #
    # # wire another slot into this one
    # # @param other [Hanuman::Outlinkable] the other stage or slot
    # # @returns this object, for chaining
    # def from(other)
    #   owner.connect(other, self)
    #   self
    # end

    # ------------------------------------------------------------------------
    # ------------------------------------------------------------------------

    # # @returns the stage, namespaced by the graph that owns it
    # def graph_id
    #   [(owner ? '(orphan)' : owner.graph_id), name].compact.join('.')
    # end

    def self.stage_type()  typename.gsub(/.*\W/, '') ; end
    def stage_type()       self.class.stage_type     ; end

    alias_method :wire, :receive!

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
