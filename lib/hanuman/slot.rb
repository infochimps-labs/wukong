module Hanuman
  #
  # Slot holds the
  #
  module Inlinkable
    extend Gorillib::Concern

    def set_input(stage)
      write_attribute(:input, stage)
      self
    end

    # wire another slot into this one
    # @param other [Hanuman::Outlinkable] the other stage of slot
    # @returns this object, for chaining
    def <<(other)
      from(other)
      self
    end

    # wire another slot into this one
    # @param other [Hanuman::Outlinkable] the other stage or slot
    # @returns this object, for chaining
    def from(other)
      owner.connect(other, self)
      self
    end
  end

  module Outlinkable
    extend Gorillib::Concern

    def set_output(stage)
      write_attribute(:output, stage)
      self
    end

    # wire this slot into another slot
    # @param other [Hanuman::Slot] the other stage
    # @returns the other slot
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

  Stage.class_eval do
    def self.has_input
      include Hanuman::IsOwnInputSlot
    end

    def self.has_output
      include Hanuman::IsOwnOutputSlot
    end
  end

  class Slot
    include  Gorillib::Builder
    field    :name,  Symbol
    field    :stage, Hanuman::Stage
    def owner
      stage.owner
    end
    def to_key() name ; end
  end

  class InputSlot < Slot
    include  Hanuman::Inlinkable
    field    :input,    Hanuman::Stage, :writer => false, :tester => true, :doc => 'stage/slot in graph that feeds into this one'
    def other() input ; end
  end

  class OutputSlot < Slot
    include  Hanuman::Outlinkable
    field    :output,   Hanuman::Stage, :writer => false, :tester => true, :doc => 'stage/slot in graph this one feeds into'
    def other() ouput ; end
  end

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

      def inslot_fields
        fields.select{|_, field| field.is_a?(InputSlotField) }
      end

      def inslot_field?(field_name)
        fields[field_name].is_a?(InputSlotField)
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
    end

    class SlotField < Gorillib::Model::Field
      self.visibilities = visibilities.merge(:reader => true, :writer => true, :tester => true)
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

  end

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

    def inslots
      super + splat_inslots.to_a
    end
  end

  module SplatOutputs
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
