module Hanuman

  #
  # Slottable: declare slots
  #
# <<<<<<< HEAD
#   module IsOwnInputSlot
#     extend  Gorillib::Concern
#     include Inlinkable
#     included do
#       magic   :input,    Hanuman::Stage, :writer => false, :tester => true, :doc => 'stage/slot in graph that feeds into this one'
#     end
#     def inputs
#       input?  ? [input] : []
#     end
#   end

#   #
#   # For stages that can be linked to directly
#   # Including this means your stage has exactly one output (itself).
#   #
#   module IsOwnOutputSlot
#     extend  Gorillib::Concern
#     include Outlinkable
#     included do
#       magic  :output,   Hanuman::Stage, :writer => false, :tester => true, :doc => 'stage/slot in graph this one feeds into'
#     end
#     def outputs
#       output? ? [output] : []
#     end
#   end

#   #
#   # For stages with named slots
#   #
#   # A named slot is a special kind of field: saying
#   #
#   #   consumes :brain
#   #
#   # gives your class
#   #
#   # * A normal attribute `brain_slot`
#   # * methods `brain_slot`, `receive_brain_slot` to go with it
#   # * method `brain`, returning the item (if any) connected to the brain slot
#   # * method `brain=` (alias for `receive_brain`) that links the brain slot with the given item
#   #
#   # @note that at the moment you can't have an input and an output with the same name.

  # Including Slottable lets you declare slots at the instance level or the class level.
  #
  module Slottable
    # included do
    #   collection :outslots, Hanuman::OutputSlot, :key_method => :name

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
      define_singleton_method(slot.name){ slot } unless slot.dummy?
      _reset_slot_fields
      slot
    end

    # * creates named slot and saves it in `inslots` collection
    # * defines instance method for that slot
    # @return [Hanuman::Slot] the created-or-updated slot
    def produce(slot_name, schema, options={})
      skip_method = options.delete(:skip_method)
      slot = outslots.update_or_add(slot_name, options.merge(stage: self, schema: schema, _type: OutputSlot))
      define_singleton_method(slot.name){ slot } unless slot.dummy?
      _reset_slot_fields
      slot
    end

    # @return [Array[Hanuman::Stage]] list of all sources this stage is connected from
    def sources
      @_sources ||= inslots.values.map{|slot|  slot.source }
    end

    # @return [Array[Hanuman::Stage]] list of all sinks this stage is connected into
    def sinks
      @_sinks   ||= outslots.values.map{|slot| slot.sink   }
    end

    def input(slot_name)  ; inslots.fetch(slot_name)  ; end
    def output(slot_name) ; outslots.fetch(slot_name) ; end

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

    def to_inspectable
      super.tap do |hsh|
        if inslots.present?  then hsh[:inslots]  = inslots.keys.join(",")  else hsh.delete(:inslots)  ; end
        if outslots.present? then hsh[:outslots] = outslots.keys.join(",") else hsh.delete(:outslots) ; end
      end
    end

    private
      # called when sources, sinks, etc are modified; next call to accessors will rebuild
      def _reset_slot_fields
        remove_instance_variable('@_sources') if instance_variable_defined?('@_sources')
        remove_instance_variable('@_sinks')   if instance_variable_defined?('@_sinks')
      end
    public

    # class SlotField < Gorillib::Model::Field
    #   self.visibilities = visibilities.merge(:reader => true, :writer => false, :tester => false)
    #   field :basename,   Symbol
    #   field :stage_type, Whatever, :doc => 'type for stages this slot accepts'
    #   class_attribute :slot_type

    #   def initialize(model, basename, type, options={})
    #     name = "#{basename}_slot"
    #     options[:stage_type] = type
    #     slot_type = self.slot_type
    #     options[:basename] = basename
    #     options[:default]  = ->{ slot_type.new(:name => basename, :stage => self) }
    #     super(model, name, slot_type, options)
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
        define_method(slot_name){ outslots.fetch(slot_name) }
      end

      def inspect
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
    include Inlinkable
    include Slottable

    # included do
    #   collection :splat_inslots, Hanuman::InputSlot, :key_method => :name
    # end

    # def set_input(stage)
    #   slot = Hanuman::InputSlot.new(:name => stage.name, :stage => self, :input => stage)
    #   self.splat_inslots << slot
    #   slot
    # end

    # def has_input?(slot_name)
    #   self.splat_inslots.keys.include?(slot_name)
    included do |base|
      base.collection(:splat_sources, Whatever, doc: 'stages in graph that feed into this one')
    end

    # connect an external stage to this input
    def set_source(stage)
      slot = consume("#{stage.name}-#{inslots.length}", Whatever, :dummy => true)
      slot.set_source(stage)
    end
  end

  #
  # SplatOutputs: multiple outbound connections, all treated identically
  #
  module SplatOutputs
    extend Gorillib::Concern
    include Outlinkable
    include Slottable

    # included do
    #   collection :splat_outslots, Hanuman::OutputSlot, :key_method => :name
    # end

    # def set_output(stage)
    #   slot = Hanuman::OutputSlot.new(
    #     :name => stage.name, :stage => self, :output => stage)
    #   self.outslots << slot
    #   slot
    # end

    # def outputs
    #   outslots.to_a.map{|slot| slot.output }
    # end

    # def into(*others)
    #   others.each{|other| super(other)}
    #   self
    # connect an external stage to this output
    def set_sink(stage)
      slot = produce("#{stage.name}-#{outslots.length}", Whatever, :dummy => true)
      slot.set_sink(stage)
    end
  end
  
end
