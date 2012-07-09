module Hanuman

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

    def inspect(*args)
      str = super ; terminal_char = str.slice!(-1)
      str << %Q{ inslots=#{inslots.keys.join(",")}}   if inslots.present?
      str << %Q{ outslots=#{outslots.keys.join(",")}} if outslots.present?
      str << terminal_char
    end

    private
      # called when sources, sinks, etc are modified; next call to accessors will rebuild
      def _reset_slot_fields
        remove_instance_variable('@_sources') if instance_variable_defined?('@_sources')
        remove_instance_variable('@_sinks')   if instance_variable_defined?('@_sinks')
      end
    public

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
    include Inlinkable
    include Slottable

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

    # connect an external stage to this output
    def set_sink(stage)
      slot = produce("#{stage.name}-#{outslots.length}", Whatever, :dummy => true)
      slot.set_sink(stage)
    end
  end
  
end
