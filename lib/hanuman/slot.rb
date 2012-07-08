module Hanuman

  class Source < Stage  ; end
  class Sink   < Stage  ; end

  # A stand-in source; throws an error if you try to use it
  StubSource = Stage.new(name: :stub_source)

  # A stand-in sink; throws an error if you try to use it
  StubSink   = Stage.new(name: :stub_sink) do
    define_singleton_method(:process){|*args| raise NoMethodError, "Tried to send #{args.inspect} into stub sink" }
    define_singleton_method(:inspect){|*| '<StubSink>' }
  end

  #
  # Wiring point for a stage connection
  #
  module InputSlotted
    extend Gorillib::Concern

    included do |base|
      base.field(:source,   Hanuman::Stage, default: ->{ Hanuman::StubSource }, writer: false, tester: true,
        doc: 'stage in graph that feeds into this one')
    end

    # @return [Array[Hanuman::Stage]] list of all sources this stage is connected from
    def sources() [source] ; end

    # @param stage [Hanuman::Stage] the new stage to accept input from
    def set_source(stage)
      write_attribute(:source, stage)
    end

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

  #
  # For stages with exactly one output
  #
  module OutputSlotted
    extend Gorillib::Concern

    included do |base|
      base.field(:sink,     Hanuman::Stage, default:  ->{ Hanuman::StubSink }, writer: false, tester: true,
        doc: 'stage in graph this one feeds into')
    end

    # @return [Array[Hanuman::Stage]] list of all sinks this stage is connected to
    def sinks() [sink] ; end

    # @param stage [Hanuman::Stage] the new stage to target
    def set_sink(stage)
      write_attribute(:sink, stage)
    end

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

  # ______________________________________________________________________
  # ______________________________________________________________________

  class Slot
    class SlotField < Gorillib::Model::Field
      self.visibilities = visibilities.merge(reader: true, writer: false, tester: false)
      field :schema, Whatever, doc: "type of data transmitted by this field's slot"

      def initialize(name, type, model, options={})
        schema = options[:schema]
        options[:default]  = ->{ type.new(stage: self, name: name, schema: schema) }
        p [name, type, model, options]
        super(name, type, model, options)
      end
    end
    class InputSlotField  < SlotField ; end
    class OutputSlotField < SlotField ; end

    class SlotCollection < Gorillib::ModelCollection
      include Gorillib::Collection::CommonAttrs
      self.key_method = :name
      self.item_type = Hanuman::Slot

      # the stage that owns this collection
      attr_reader :owner

      def initialize(owner, options={})
        super(options)
        @owner = owner
        @common_attrs = common_attrs.merge(owner: owner)
        p [self, options, common_attrs]
      end

      def receive_item(*args)
        p ['receive_item', args, key_method]
        val = super
        p [val, val.attributes]
        val
      end
    end
  end

  #
  # MultiInputs: multiple inbound connections, all treated identically
  #

  # on class:
  # * consumes :slot_name => schema, :slot_name => schema
  #
  # `consume foo, FooType, options` produces
  # * on class:   `.input`
  # * on object: method `foo`
  # * on object: `input(:foo)`, equivalent to `inputs[:foo]`
  # *
  #

  module MultiInputs
    extend Gorillib::Concern

    def consume(slot_name, schema, options={})
      slot = inslots.update_or_add(slot_name,  options.merge(stage: self, schema: schema, _type: InputSlot))
      define_slot_reader(slot)
      slot
    end

    def produce(slot_name, schema, options={})
      slot = outslots.update_or_add(slot_name, options.merge(stage: self, schema: schema, _type: OutputSlot))
      define_slot_reader(slot)
      slot
    end

    def define_slot_reader(slot)
      p slot
      define_singleton_method(slot.name){ slot }
    end

    def default_inslots
      Slot::SlotCollection.new(self)
    end

    def default_outslots
      Slot::SlotCollection.new(self)
    end

    included do |base|
      base.field :inslots,  Slot::SlotCollection, default: instance_method(:default_inslots)
      base.field :outslots, Slot::SlotCollection, default: instance_method(:default_outslots)
    end

    module ClassMethods
      def consume(slot_name, schema, options={})
        field slot_name, InputSlot,  {schema: schema, field_type: Slot::InputSlotField}.merge(options)
      end
      def produce(slot_name, options={})
        field slot_name, OutputSlot, {schema: schema, field_type: Slot::OutputSlotField}.merge(options)
      end

      def inslot_fields()   fields.select{|_, field| field.is_a?(InputSlotField)  } ; end
      def outslot_fields()  fields.select{|_, field| field.is_a?(OutputSlotField) } ; end

      def inslot_field?(field_name)  ; fields[field_name].is_a?(InputSlotField)  ; end
      def outslot_field?(field_name) ; fields[field_name].is_a?(OutputSlotField) ; end

      # # Ensure that classes inherit all their parents' fields, even if fields
      # # are added after the child class is defined.
      # def _reset_descendant_fields
      #   super
      #   ObjectSpace.each_object(::Class) do |klass|
      #     klass.__send__(:remove_instance_variable, '@_inslot_fields')  if (klass <= self) && klass.instance_variable_defined?('@_inslot_fields')
      #     klass.__send__(:remove_instance_variable, '@_outslot_fields') if (klass <= self) && klass.instance_variable_defined?('@_outslot_fields')
      #   end
      # end
    end

  end

  # #
  # # MultiOutputs: multiple outbound connections, all treated identically
  # #
  # module MultiOutputs
  #   extend Gorillib::Concern
  #
  #   included do |base|
  #     base.collection(:sinks, Whatever, doc: 'stages in graph that this feeds into')
  #     base.magic(:produces, Whatever, default: Whatever, writer: false,
  #       doc: 'expected type for produced data')
  #   end
  #
  #   # connect an external stage to this output
  #   def set_sink(stage)
  #     sinks << stage
  #   end
  #
  #   # wire this stage's output into another stage's input
  #   # @param other [Hanuman::InputSlotted] the other stage
  #   # @returns the other stage
  #   def >(other)
  #     _, other = owner.connect(self, other)
  #     other
  #   end
  #
  #   # wire this stage's output into another stage's input
  #   # @param other [Hanuman::Stage]the other stage
  #   # @returns this stage, for chaining
  #   def into(other)
  #     owner.connect(self, other)
  #     self
  #   end
  # end

  # ______________________________________________________________________
  # ______________________________________________________________________

  #
  # SplatInputs: multiple inbound connections, all treated identically
  #
  module SplatInputs
    extend Gorillib::Concern

    included do |base|
      base.collection(:sources, Whatever, doc: 'stages in graph that feed into this one')
    end

    # connect an external stage to this input
    def set_source(stage)
      sources << stage
    end

    # wire from another stage's output into this stage's input
    # @param other [Hanuman::Outlinkable] the other stage
    # @returns this object, for chaining
    def <<(other)
      from(other)
      self
    end

    # wire from another stage's output into this stage's input
    # @param other [Hanuman::Outlinkable] the other stage
    # @returns this object, for chaining
    def from(other)
      owner.connect(other, self)
      self
    end
  end

  #
  # SplatOutputs: multiple outbound connections, all treated identically
  #
  module SplatOutputs
    extend Gorillib::Concern

    included do |base|
      base.collection(:sinks, Whatever, doc: 'stages in graph that this feeds into')
    end

    # connect an external stage to this output
    def set_sink(stage)
      sinks << stage
    end

    # wire this stage's output into another stage's input
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

  # ______________________________________________________________________
  # ______________________________________________________________________

  #
  # Apply slot modules to stage subtypes
  #

  Action.class_eval do
    include Hanuman::InputSlotted
    include Hanuman::OutputSlotted

    # magic(:consumed, Whatever,       default: Whatever, writer: false,
    #   doc: 'expected type for consumed data')
    # magic(:product, Whatever, default: Whatever, writer: false,
    #   doc: 'expected type for produced data')

    def input()  ; self ; end
    def output() ; self ; end
  end

  Product.class_eval do
    include Hanuman::InputSlotted
    include Hanuman::OutputSlotted
  end

  Source.class_eval do
    include OutputSlotted
  end
  Sink.class_eval do
    include InputSlotted
  end

  class Slot
    include Gorillib::Builder
    field :name,   Symbol,   position: 0, doc: 'name (unique on its stage) for this slot'
    field :schema, Whatever, position: 1, doc: "type of data transmitted by this field's slot"
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
      "#{stage.graph_id}:#{name}"
    end

  end

  class InputSlot < Slot
    include InputSlotted

    def process(*args) ; stage.process_input(self.name, *args) ; end
  end

  class OutputSlot < Slot
    include Hanuman::InputSlotted
    include Hanuman::OutputSlotted

    def process(*args)
      sink.process(*args)
    rescue StandardError => err ; err.polish("#{self.graph_id}: emitting #{args.inspect} to #{sink.inspect}") rescue nil ; raise
    end
  end

end
