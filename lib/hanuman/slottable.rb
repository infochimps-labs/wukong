module Hanuman
  #
  # For stages that can be linked to directly
  # Including this means your stage has exactly one input (itself).
  #
  module IsOwnInputSlot
    extend  Gorillib::Concern
    include Inlinkable
    included do
      field   :input,    Hanuman::Stage, :writer => false, :tester => true, :doc => 'stage/slot in graph that feeds into this one'
    end
    def inputs
      input?  ? [input] : []
    end
  end

  #
  # For stages that can be linked to directly
  # Including this means your stage has exactly one output (itself).
  #
  module IsOwnOutputSlot
    extend  Gorillib::Concern
    include Outlinkable
    included do
      field  :output,   Hanuman::Stage, :writer => false, :tester => true, :doc => 'stage/slot in graph this one feeds into'
    end
    def outputs
      output? ? [output] : []
    end
  end

  #
  # For stages with named slots
  #
  # A named slot is a special kind of field: saying
  #
  #   consumes :brain
  #
  # gives your class
  #
  # * A normal attribute `brain_slot`
  # * methods `brain_slot`, `receive_brain_slot` to go with it
  # * method `brain`, returning the item (if any) connected to the brain slot
  # * method `brain=` (alias for `receive_brain`) that links the brain slot with the given item
  #
  # @note that at the moment you can't have an input and an output with the same name.
  #
  module Slottable
    extend Gorillib::Concern
    include Inlinkable
    include Outlinkable

    included do
      collection :outslots, Hanuman::OutputSlot
    end

    def inputs
      inslots.to_a.map{|slot| slot.input }.compact
    end

    def inslots
      self.class.inslot_fields.map{|_, slot_field| read_attribute(slot_field.name) }
    end

    def handle_extra_attributes(attrs)
      self.class.inslot_fields.each do |_, field|
        field_name = field.basename
        next unless attrs.has_key?(field_name)
        self.public_send(:"receive_#{field_name}", attrs.delete(field_name))
      end
      super(attrs)
    end

    module ClassMethods
      def consumes(name, options={})
        field name, Hanuman::Stage, {:field_type => InputSlotField}.merge(options)
      end
      def produces(name, options={})
        field name, Hanuman::Stage, {:field_type => OutputSlotField}.merge(options)
      end

      def define_slot_reader(field)
        meth_name  = field.basename
        slot_name  = field.name
        type       = field.type
        define_meta_module_method(meth_name, true) do ||
          begin
            slot = read_attribute(slot_name) or return nil
            slot.other
          rescue StandardError => err ; err.polish("#{self.class}.#{meth_name}") rescue nil ; raise ; end
        end
      end

      def define_inslot_receiver(field)
        meth_name  = field.basename
        slot_name  = field.name
        type       = field.type
        define_meta_module_method("receive_#{meth_name}", true) do |stage|
          begin
            slot = read_attribute(slot_name) or return nil
            slot.from(stage)
            self
          rescue StandardError => err ; err.polish("#{self.class} set slot #{meth_name} to #{stage}") rescue nil ; raise ; end
        end
        meta_module.module_eval do
          alias_method "#{meth_name}=", "receive_#{meth_name}"
        end
      end

      def define_outslot_receiver(field)
        meth_name  = field.basename
        slot_name  = field.name
        type       = field.type
        define_meta_module_method("receive_#{meth_name}", true) do |stage|
          begin
            slot = read_attribute(slot_name) or return nil
            slot.into(stage)
            self
          rescue StandardError => err ; err.polish("#{self.class} set slot #{meth_name} to #{stage}") rescue nil ; raise ; end
        end
        meta_module.module_eval do
          alias_method "#{meth_name}=", "receive_#{meth_name}"
        end
      end

      def inslot_fields
        fields.select{|_, field| field.is_a?(InputSlotField) }
      end

      def inslot_field?(field_name)
        fields[field_name].is_a?(InputSlotField)
      end
    end

    class SlotField < Gorillib::Model::Field
      self.visibilities = visibilities.merge(:reader => true, :writer => false, :tester => false)
      field :basename, Symbol
      field :stage_type, Whatever, :doc => 'type for stages this slot accepts'
      class_attribute :slot_type

      def initialize(basename, type, model, options={})
        name = "#{basename}_slot"
        options[:stage_type] = type
        slot_type = self.slot_type
        options[:basename] = basename
        options[:default]  = ->{ slot_type.new(:name => basename, :stage => self) }
        super(name, slot_type, model, options)
      end
    end

    class InputSlotField < SlotField
      self.slot_type = Hanuman::InputSlot
      def inscribe_methods(model)
        model.__send__(:define_slot_reader, self)
        model.__send__(:define_inslot_receiver, self)
        super
      end
    end

    class OutputSlotField < SlotField
      self.slot_type = Hanuman::OutputSlot
      def inscribe_methods(model)
        model.__send__(:define_slot_reader, self)
        model.__send__(:define_outslot_receiver, self)
        super
      end
    end

  end # Slottable

  module SplatInputs
    extend  Gorillib::Concern
    include Slottable

    included do
      collection :splat_inslots, Hanuman::InputSlot
    end

    def set_input(stage)
      slot = Hanuman::InputSlot.new(:name => stage.name, :stage => self, :input => stage)
      self.splat_inslots << slot
      slot
    end

    def has_input?(slot_name)
      self.splat_inslots.keys.include?(slot_name)
    end

    def inslots
      super + splat_inslots.to_a
    end
  end

  module SplatOutputs
    extend  Gorillib::Concern
    include Slottable

    included do
      collection :splat_outslots, Hanuman::OutputSlot
    end

    def set_output(stage)
      slot = Hanuman::OutputSlot.new(
        :name => stage.name, :stage => self, :output => stage)
      self.outslots << slot
      slot
    end

    def outputs
      outslots.to_a.map{|slot| slot.output }
    end

    def into(*others)
      others.each{|other| super(other)}
      self
    end
  end

end
