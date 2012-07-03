module Hanuman

  #
  # `Stage` is the fundamental Hanuman building block; stages represent nodes on a
  # hanuman graph. `Action`s, `Resource`s and `Graph`s (among others) all inherit from
  # and fit the contract of `Stage`.
  #
  # `Stage` has the following minimal contract:
  #
  # * a fundamental identity (`name`, `doc`, `stage_type`, and `graph_id`)
  # * the `sources` and `sinks` it connects to and its `owner` graph
  # * lifecycle methods (`setup`, `stop` and `report`)
  #
  class Stage
    include Gorillib::Builder
    alias_method :configure, :receive!

    magic      :name,    String,         :doc => 'name of this stage'
    member     :owner,   Whatever,       :doc => 'the graph this stage sits in'
    magic      :doc,     String,         :doc => 'freeform description of this stage type'

    # ------------------------------------------------------------------------
    # ------------------------------------------------------------------------

    # @returns the stage, namespaced by the graph that owns it
    def graph_id
      [(owner ? '(orphan)' : owner.graph_id), name].compact.join('.')
    end

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
