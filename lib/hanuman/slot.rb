module Hanuman

  # A stand-in source; throws an error if you try to use it
  StubSource = Stage.new(name: :stub_source)

  # A stand-in sink; throws an error if you try to use it
  StubSink   = Stage.new(name: :stub_sink) do
    define_singleton_method(:process){|*args| raise NoMethodError, "Tried to send #{args.inspect} into stub sink" }
    define_singleton_method(:inspect){|*| '<StubSink>' }
  end

  # ______________________________________________________________________
  # ______________________________________________________________________

  module Inlinkable
    # wire another stage into this one
    # @param other [Hanuman::Outlinkable] the other stage
    # @returns this object, for chaining
    def <<(other)
      from(other)
      self
    end

    # wire another stage into this one
    # @param other [Hanuman::Outlinkable] the other stage
    # @returns this object, for chaining
    def from(other)
      owner.connect(other, self)
      self
    end
  end

  module Outlinkable
    # wire this stage into another one
    # @param other [Hanuman::InputSlotted] the other stage
    # @returns the other stage
    def >(other)
      _, other = owner.connect(self, other)
      other
    end

    # wire this stage's output into another stage's input
    # @param other [Hanuman::Stage]the other stage
    # @returns this stage, for chaining
    def into(other)
      owner.connect(self, other)
      self
    end
  end

  class Slot
    include Gorillib::Builder
    field :name,   Symbol,   position: 0, doc: 'name (unique on its stage) for this slot'
    field :schema, Whatever, position: 1, doc: "type of data transmitted by this field's slot"
    field :dummy,  :boolean,              doc: "type of data transmitted by this field's slot", tester: true, default: false
    attr_accessor :stage
    #
    def initialize(*args, &block)
      attrs = args.extract_options!
      @stage = attrs.delete(:stage) or raise "You must supply a stage for #{self.class}: #{args}, #{attrs}"
      super(*args, attrs, &block)
    end

    def owner
      stage.is_a?(Hanuman::Graph) ? stage : stage.owner
    end

    def graph_id
      "#{stage.graph_id}-#{name}"
    end

    def wired?
      source? || sink?
    end

    #
    # Stores the input slots / output slot
    #
    class SlotCollection < Gorillib::ModelCollection
      include Gorillib::Collection::CommonAttrs
      self.key_method = :name
      self.item_type  = Hanuman::Slot
      # the stage that owns this collection
      attr_reader :owner

      def initialize(owner, options={})
        super(options)
        @owner = owner
        @common_attrs = common_attrs.merge(owner: owner)
      end
    end
  end

  # ______________________________________________________________________
  # ______________________________________________________________________

  #
  # Wiring point for a stage connection
  #
  module InputSlotted
    extend  Gorillib::Concern
    include Inlinkable

    included do |base|
      base.field(:source, Hanuman::Stage, writer: false, tester: true,
        doc: 'stage in graph that feeds into this one')
    end

    # @return [Array[Hanuman::Stage]] list of all sources this stage is connected from
    def sources() [source] ; end

    # @param stage [Hanuman::Stage] the new stage to accept input from
    def set_source(stage)
      write_attribute(:source, stage)
      self
    end
  end

  #
  # For stages with exactly one output
  #
  module OutputSlotted
    extend  Gorillib::Concern
    include Outlinkable

    included do |base|
      base.field(:sink, Hanuman::Stage, writer: false, tester: true,
        doc: 'stage in graph this one feeds into')
    end

    # @return [Array[Hanuman::Stage]] list of all sinks this stage is connected to
    def sinks() [sink] ; end

    # @param stage [Hanuman::Stage] the new stage to target
    def set_sink(stage)
      write_attribute(:sink, stage)
      self
    end
  end

  class InputSlot < Slot
    # include  Hanuman::Inlinkable
    # magic    :input,    Hanuman::Stage, :writer => false, :tester => true, :doc => 'stage/slot in graph that feeds into this one'
    # def other() input ; end
    include Hanuman::InputSlotted
    include Hanuman::OutputSlotted

    def process(*args)
      stage.process_input(self.name, *args)
    rescue StandardError => err ; err.polish("#{self.graph_id}: emitting #{args.inspect} to #{stage.inspect}") rescue nil ; raise
    end
  end

  class OutputSlot < Slot
    # include  Hanuman::Outlinkable
    # magic    :output,   Hanuman::Stage, :writer => false, :tester => true, :doc => 'stage/slot in graph this one feeds into'
    # def other() ouput ; end
    include Hanuman::InputSlotted
    include Hanuman::OutputSlotted

    def process(*args)
      sink.process(*args)
    rescue StandardError => err ; err.polish("#{self.graph_id}: emitting #{args.inspect} to #{sink.inspect}") rescue nil ; raise
    end
  end
end
