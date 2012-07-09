module Hanuman

  # ______________________________________________________________________
  # ______________________________________________________________________

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
  # Slottable: declare slots
  #
  # Including Slottable lets you declare slots at the instance level or the class level.
  #
  module Slottable
    extend Gorillib::Concern

    included do |base|
      base.field :inslots,  Slot::SlotCollection, default: instance_method(:default_inslots)
      base.field :outslots, Slot::SlotCollection, default: instance_method(:default_outslots)

      # FIXME: I don't want all the machinery of a field here, but what we give up is the
      # to have superclass modifications propogate to its inheritors
      base.class_attribute :class_inslots  ; base.class_inslots  = Hash.new
      base.class_attribute :class_outslots ; base.class_outslots = Hash.new
    end

    # * creates named slot and saves it in `inslots` collection
    # * defines instance method for that slot
    # @return [Hanuman::Slot] the created-or-updated slot
    def consume(slot_name, schema, options={})
      slot = inslots.update_or_add(slot_name,  options.merge(stage: self, schema: schema, _type: InputSlot))
      define_singleton_method(slot.name){ slot }
      remove_instance_variable('@_sources')
      slot
    end

    # * creates named slot and saves it in `inslots` collection
    # * defines instance method for that slot
    # @return [Hanuman::Slot] the created-or-updated slot
    def produce(slot_name, schema, options={})
      slot = outslots.update_or_add(slot_name, options.merge(stage: self, schema: schema, _type: OutputSlot))
      define_singleton_method(slot.name){ slot }
      remove_instance_variable('@_sinks')
      slot
    end

    # @return [Array[Hanuman::Stage]] list of all sources this stage is connected from
    def sources
      @_sources ||= inslots.to_a.each{|slot|  slot.source }
    end

    # @return [Array[Hanuman::Stage]] list of all sinks this stage is connected into
    def sinks
      @_sinks   ||= outslots.to_a.each{|slot| slot.sink   }
    end

    def default_inslots
      write_attribute(:inslots, Slot::SlotCollection.new(self))
      class_inslots.each{|slot_name, args| consume(slot_name, *args) }
      inslots
    end

    def default_outslots
      write_attribute(:outslots, Slot::SlotCollection.new(self))
      class_outslots.each{|slot_name, args| produce(slot_name, *args) }
      outslots
    end

    module ClassMethods
      # define a named input slot
      def consume(slot_name, *args)
        self.class_inslots  = self.class_inslots.merge(slot_name => args)
        # we're doing some sleight-of-hand here: the call to inslots will slap a
        # singleton method on top of these. That's OK; they do the same thing
        define_method(slot_name){ inslots.fetch(slot_name) }
      end

      # define a named output slot
      def produce(slot_name, *args)
        self.class_outslots = self.class_outslots.merge(slot_name => args)
        define_method(slot_name){ inslots.fetch(slot_name) }
      end

      def inspect(*args)
        str = super ; terminal_char = str.slice!(-1)
        str << %Q{ inslots=#{class_inslots.keys.join(",")}}   if class_inslots.present?
        str << %Q{ outslots=#{class_outslots.keys.join(",")}} if class_outslots.present?
        str << terminal_char
      end
    end
  end

  # ______________________________________________________________________
  # ______________________________________________________________________

  #
  # SplatInputs: multiple inbound connections, all treated identically
  #
  module SplatInputs
    extend Gorillib::Concern
    include Slottable

    included do |base|
      base.collection(:splat_sources, Whatever, doc: 'stages in graph that feed into this one')
    end

    # connect an external stage to this input
    def set_source(stage)
      splat_sources << stage
    end

    def sources
      (defined?(super) ? super : []) + splat_sources.to_a
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
    include Slottable

    included do |base|
      base.collection(:splat_sinks, Whatever, doc: 'stages in graph that this feeds into')
    end

    # connect an external stage to this output
    def set_sink(stage)
      splat_sinks << stage
    end

    def sinks
      (defined?(super) ? super : []) + splat_sinks.to_a
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

end
