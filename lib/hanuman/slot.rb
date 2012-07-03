module Hanuman

  class Source < Stage  ; end
  class Sink   < Stage  ; end

  # A stand-in source; throws an error if you try to use it
  StubSource = Stage.new(name: :stub_source)

  # A stand-in sink; throws an error if you try to use it
  StubSink   = Stage.new(name: :stub_sink)

  #
  # Wiring point for a stage connection
  #
  module InputSlotted
    extend Gorillib::Concern

    included do |base|
      base.field(:source,   Hanuman::Stage, :default => ->{ Hanuman::StubSource }, :writer => false, :tester => true,
        :doc => 'stage/slot in graph that feeds into this one')
      base.field(:consumes, Whatever,       :default => Whatever, :writer => false,
        :doc => 'expected type for consumed data')
    end

    # connect an external stage to this input slot
    def set_source(stage)
      write_attribute(:source, stage)
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

  #
  # For stages with exactly one output
  #
  module OutputSlotted
    extend Gorillib::Concern

    included do |base|
      base.field(:sink,     Hanuman::Stage, :default =>  ->{ Hanuman::StubSink }, :writer => false, :tester => true,
        :doc => 'stage/slot in graph this one feeds into')
      base.magic(:produces, Whatever, :default => Whatever, :writer => false,
        :doc => 'expected type for consumed data')
    end

    def set_sink(stage)
      write_attribute(:sink, stage)
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

  Source.class_eval{ include OutputSlotted }
  Sink.class_eval{   include InputSlotted  }

  class Action
    include Hanuman::InputSlotted
    include Hanuman::OutputSlotted
  end


  class Slot
    include Gorillib::Builder
    field :name, Symbol, position: 0, doc: 'name (unique on its stage) for this slot'
  end

  class InputSlot < Slot
    include InputSlotted
  end

  class OututSlot < Slot
    include OutputSlotted
  end











  # magic :input,  Hanuman::Stage
  # magic :output, Hanuman::Stage
  #
  # def inputs()  [input]  ; end
  # def outputs() [output] ; end
  #
  # def set_input(slot_name, stage)
  #   raise ArgumentError, "there's only one input (':default') on #{self}" unless slot_name == :default
  #   write_attribute(:input, stage)
  # end
  # def set_output(slot_name, stage)
  #   raise ArgumentError, "there's only one output (':default') on #{self}" unless slot_name == :default
  #   write_attribute(:output, stage)
  # end

  # field      :inputs,  Gorillib::Collection, :of => Hanuman::Stage, :doc => 'inputs to this stage',  :default => ->{ Gorillib::Collection.new }
  # field      :outputs, Gorillib::Collection, :of => Hanuman::Stage, :doc => 'outputs of this stage', :default => ->{ Gorillib::Collection.new }
  #
  #
  # def source(label) inputs[label].stage  ; end
  # def sink(  label) outputs[label].stage ; end
  #
  # def input( label) inputs[label] ; end
  # def output(label) inputs[label] ; end
  #
  # # wire this slot into another slot
  # # @param other [Hanuman::Slot] the other stage
  # # @returns the other slot
  # def >(other)
  #   _, other = owner.connect(self, other)
  #   other
  # end
  #
  # # wire this stage's output into another stage's input
  # # @param other [Hanuman::Stage]the other stage
  # # @returns this stage, for chaining
  # def into(other)
  #   owner.connect(self, other)
  #   self
  # end
  #
  # # wire another slot into this one
  # # @param other [Hanuman::Outlinkable] the other stage of slot
  # # @returns this object, for chaining
  # def <<(other)
  #   from(other)
  #   self
  # end
  #
  # # wire another slot into this one
  # # @param other [Hanuman::Outlinkable] the other stage or slot
  # # @returns this object, for chaining
  # def from(other)
  #   owner.connect(other, self)
  #   self
  # end

  # module PluralInput
  #   extend Gorillib::Concern
  #   # include Inlinkable
  #   # include Outlinkable
  #
  #   included do
  #     collection :inputs, Hanuman::OutputSlot
  #   end
  #
  # end

  # class Stage
  #   def consumes(name, options={})
  #     magic name, Hanuman::Stage, {:field_type => InputSlotField}.merge(options)
  #   end
  #   def produces(name, options={})
  #     magic name, Hanuman::Stage, {:field_type => OutputSlotField}.merge(options)
  #   end
  #
  #   def define_slot_reader(field)
  #     meth_name  = field.basename
  #     slot_name  = field.name
  #     type       = field.type
  #     define_meta_module_method(meth_name, true) do ||
  #       begin
  #         slot = read_attribute(slot_name) or return nil
  #         slot.other
  #       rescue StandardError => err ; err.polish("#{self.class}.#{meth_name}") rescue nil ; raise ; end
  #     end
  #   end
  #
  #   def define_inslot_receiver(field)
  #     meth_name  = field.basename
  #     slot_name  = field.name
  #     type       = field.type
  #     define_meta_module_method("receive_#{meth_name}", true) do |stage|
  #       begin
  #         slot = read_attribute(slot_name) or return nil
  #         slot.from(stage)
  #         self
  #       rescue StandardError => err ; err.polish("#{self.class} set slot #{meth_name} to #{stage}") rescue nil ; raise ; end
  #     end
  #     meta_module.module_eval do
  #       alias_method "#{meth_name}=", "receive_#{meth_name}"
  #     end
  #   end
  #
  #   def define_outslot_receiver(field)
  #     meth_name  = field.basename
  #     slot_name  = field.name
  #     type       = field.type
  #     define_meta_module_method("receive_#{meth_name}", true) do |stage|
  #       begin
  #         slot = read_attribute(slot_name) or return nil
  #         slot.into(stage)
  #         self
  #       rescue StandardError => err ; err.polish("#{self.class} set slot #{meth_name} to #{stage}") rescue nil ; raise ; end
  #     end
  #     meta_module.module_eval do
  #       alias_method "#{meth_name}=", "receive_#{meth_name}"
  #     end
  #   end
  #
  # class SlotField < Gorillib::Model::Field
  #   self.visibilities = visibilities.merge(:reader => true, :writer => false, :tester => false)
  #   field :basename, Symbol
  #   field :stage_type, Whatever, :doc => 'type for stages this slot accepts'
  #   class_attribute :slot_type
  #
  #   def initialize(basename, type, model, options={})
  #     name = "#{basename}_slot"
  #     options[:stage_type] = type
  #     slot_type = self.slot_type
  #     options[:basename] = basename
  #     options[:default]  = ->{ slot_type.new(:name => basename, :stage => self) }
  #     super(name, slot_type, model, options)
  #   end
  # end
  #
  # class InputSlotField < SlotField
  #   self.slot_type = Hanuman::InputSlot
  #   def inscribe_methods(model)
  #     model.__send__(:define_slot_reader, self)
  #     model.__send__(:define_inslot_receiver, self)
  #     super
  #   end
  # end
  #
  # class OutputSlotField < SlotField
  #   self.slot_type = Hanuman::OutputSlot
  #   def inscribe_methods(model)
  #     model.__send__(:define_slot_reader, self)
  #     model.__send__(:define_outslot_receiver, self)
  #     super
  #   end
  # end

end
