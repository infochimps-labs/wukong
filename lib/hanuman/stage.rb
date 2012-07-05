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

    magic      :name,    Symbol,         :doc => 'name of this stage'
    member     :owner,   Whatever,       :doc => 'the graph this stage sits in'
    magic      :doc,     String,         :doc => 'freeform description of this stage type'

    def self.doc(doc=nil)
      if doc ; @doc = doc ; end
      @doc
    end

    # ------------------------------------------------------------------------
    # ------------------------------------------------------------------------

    # @returns the stage, namespaced by the graph that owns it
    def graph_id
      [(owner ? owner.graph_id : '(orphan)'), name].compact.join('.')
    end

    def self.stage_type()  typename.gsub(/.*\W/, '') ; end
    def stage_type()       self.class.stage_type     ; end

    alias_method :wire, :receive!

    def self.register_stage(meth_name=nil, &block)
      meth_name ||= stage_type ; klass = self
      #
      Hanuman::Graph.send(:define_method, meth_name) do |*args, &block|
        begin
          # create stage
          attrs = args.extract_options!
          stage = klass.new(*args, attrs.merge(:owner => self), &block)
          # label and add to grpeh
          label = stage.read_attribute(:name) || next_label_for(stage)
          set_stage(label, stage)
        rescue StandardError => err ; err.polish("#{self.name}: #{meth_name}(#{args.map(&:inspect).join(',')})") rescue nil ; raise ; end
      end
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

    # Information about how things are going.
    def report
      self.attributes
    end
  end
end
