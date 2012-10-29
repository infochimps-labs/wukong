module Hanuman

  class Stage

    attr_accessor :label, :inlinks, :outlinks

    def self.register_stage(label = nil)
      label ||= self.to_s.underscore.to_sym
      Hanuman.add_definition_for(label, self)
    end
    
    def initialize(label)
      @label   = label
      @inlinks = @outlinks = []
    end

    def link_into(other_stage)
      outlinks << other_stage.label
      other_stage.link_from(self)
    end
    alias_method :>, :link_into
    
    def link_from(other_stage)
      inlinks << other_stage.label
    end
    
    def message
      nil
    end

    def definition
      {
        message:  message,
        label:    label, 
        create:   self.class,
        inlinks:  inlinks,
        outlinks: outlinks
      }
    end

  end

  class GraphDefinition < Stage

    def self.register_stage(label = nil)
      label ||= self.to_s.underscore.to_sym
      Hanuman.add_definition_for(label, self)
    end

    def initialize(label)
      @stages = []
      super
    end
        
    def definition
      @stages.map(&:definition)
    end
    
  end


  #
  # `Stage` is the fundamental Hanuman building block; stages represent nodes on a
  # hanuman graph. `Action`s, `Product`s and `Graph`s (among others) all inherit from
  # and fit the contract of `Stage`.
  #
  # `Stage` has the following minimal contract:
  #
  # * a fundamental identity (`name`, `doc`, `stage_type`, and `graph_id`)
  # * the `sources` and `sinks` it connects to and its `owner` graph
  # * lifecycle methods (`setup`, `stop` and `report`)
  #
  # class Stage
  #   include Gorillib::Builder

  #   magic      :name,    Symbol,         doc: 'name of this stage', tester: true
  #   member     :owner,   Whatever,       doc: 'the graph this stage sits in'
  #   magic      :doc,     String,         doc: 'freeform description of this stage'

  #   #
  #   # Informational
  #   #

  #   # freeform description of this stage type
  #   #
  #   # @param [String] doc - updates the doc string if present
  #   # @return [String] the curent doc string
  #   def self.doc(doc=nil)
  #     if doc then @doc = doc ; end
  #     @doc || stage_type
  #   end

  #   def self.stage_type()  typename.gsub(/.*\W/, '') ; end
  #   def stage_type()       self.class.stage_type     ; end

  #   # @returns the stage, namespaced by the graph that owns it
  #   def graph_id
  #     [ (owner ? owner.graph_id : '(orphan)'), name ].compact.join('.')
  #   end

  #   #
  #   # Constructs a 'magic method' on Hanuman::Graph to construct stages of this
  #   # type. You may specify the magic method's name, or as recommended rely on
  #   # the default: the class's underscored demodulized name (eg the class
  #   # `FileSink` produces a method `file_sink`).
  #   #
  #   # The magic method
  #   # * constructs the new stage instance from the given attributes,
  #   # * sets the stage's owner
  #   # * applies a label to the stage
  #   # * adds it at that spot.
  #   #
  #   # TODO: at some point, these will be inscribed on a module that you can
  #   # selectively include rather than directly on the Graph class.
  #   #
  #   def self.register_stage(meth_name=nil, klass=nil)
  #     meth_name ||= stage_type
  #     klass     ||= self
  #     #
  #     Hanuman::Graph.send(:define_method, meth_name) do |*args, &block|
  #       begin
  #         attrs = klass.attrs_hash_from_args(args).reverse_merge(:_type => klass)
  #         label = attrs[:label] || attrs[:name]
  #         stage = stages.receive_item(label, attrs, &block)
  #         as(label, stage) if label
  #         stage
  #       rescue StandardError => err ; err.polish("#{self.name}: #{meth_name}(#{args.map(&:inspect).join(',')})") rescue nil ; raise ; end
  #     end
  #   end

  #   #
  #   # Control Flow Methods
  #   # -- override these in concrete classes

  #   # Called after the graph is constructed, before the flow is run
  #   def setup
  #   end

  #   # Called to signal the flow should stop. Close any open connections, flush
  #   # buffers, stop supervised projects, etc.
  #   def stop
  #   end

  #   # Information about how things are going.
  #   def report
  #     self.attributes
  #   end

  # end
end
