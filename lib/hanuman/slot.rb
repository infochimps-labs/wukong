module Hanuman
  #
  # Slot holds the
  #
  module Inlinkable
    extend Gorillib::Concern
    included do
      field   :input,    Hanuman::Stage, :writer => false, :tester => true, :doc => 'stage/slot in graph that feeds into this one'
    end

    def set_input(stage)
      write_attribute(:input, stage)
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
    included do
      field  :output,   Hanuman::Stage, :writer => false, :tester => true, :doc => 'stage/slot in graph this one feeds into'
    end

    def set_output(stage)
      write_attribute(:output, stage)
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

  class InputSlot
    include  Gorillib::Builder
    include  Hanuman::Inlinkable
    field    :name,  Symbol
    field    :stage, Hanuman::Stage

    def owner
      stage.owner
    end
  end

  class OutputSlot
    include  Gorillib::Builder
    include  Hanuman::Outlinkable
    field    :name,  Symbol
    field    :stage, Hanuman::Stage

    def owner
      stage.owner
    end
  end

  class Slottable

    def self.consumes

    end

  end


    # collection :inputs,  Hanuman::Stage
    # collection :outputs, Hanuman::Stage
    #
    # def set_input(name, stage)
    #   set_collection_item(:inputs, name, stage)
    # end
    # def set_output(name, stage)
    #   set_collection_item(:outputs, name, stage)
    # end
    #
    # def input(input_name=:_)
    #   get_collection_item(:inputs, input_name)
    # end
    # def output(output_name=:_)
    #   get_collection_item(:outputs, output_name)
    # end

  # class Inslot
  #   include Gorillib::Concern
  #   include Gorillib::Model
  #   field  :name, Symbol
  #   member :input, Hanuman::Stage, :writer => true
  #   member :stage, Hanuman::Stage, :writer => true
  #
  #   def owner
  #     stage.owner
  #   end
  # end
  #
  # class Stage
  #
  #   module Slottable
  #     extend Gorillib::Concern
  #
  #     def into_slot() self ; end
  #
  #     def consumes
  #     end
  #
  #
  #
  #     def input(input_name=nil)
  #       raise ArgumentError, "Processors have only one input" unless input_name.nil? || input_name.to_s == '_'
  #       read_attribute(:input)
  #     end
  #     def set_input(input_name, stage)
  #       raise ArgumentError, "Processors have only one input" unless input_name.to_s == '_'
  #       self.set_input(stage
  #     end
  #     def inputs() [input] end
  #
  #     # @return Array[Hanuman::Stage] The input to this stage
  #     def inslot(input_name=nil)
  #       raise ArgumentError, "Processors have only one input" unless input_name.nil? || input_name.to_s == '_'
  #       read_attribute(:inslot)
  #     end
  #     def inslots() [inslot] ; end
  #
  #     # # @return [Hanuman::Stage] Stage that feeds into the given input slot
  #     # def input(input_name=nil)
  #     #   inslot(input_name).stage
  #     # end
  #     # def set_input(input_name, stage)
  #     #   inslot(input_name).stage = stage
  #     # end
  #     # # @return Array[Hanuman::Stage] List holding the inputs to this stage
  #     # def inputs()
  #     #   inslots.map(&:stage)
  #     # end
  #   end
  #
  #   module SingleOutput
  #     extend Gorillib::Concern
  #     included do
  #       field :outslot,  Hanuman::Slot,  :default => Slot.new(:_), :doc => 'stage(s) in graph this one feeds into', :reader => false
  #       field   :output,   Hanuman::Stage,                           :doc => 'stage(s) in graph this one feeds into', :reader => false, :writer => true
  #     end
  #
  #     def output(output_name=nil)
  #       raise ArgumentError, "Processors have only one output" unless output_name.nil? || output_name.to_s == '_'
  #       read_attribute(:output)
  #     end
  #     def set_output(output_name, stage)
  #       raise ArgumentError, "Processors have only one output" unless output_name.to_s == '_'
  #       self.set_output stage
  #     end
  #     def outputs() [output] end
  #
  #     # @return Array[Hanuman::Stage] The output of this stage
  #     def outslot(output_name=nil)
  #       raise ArgumentError, "#{self} does not have an output slot named #{output_name}" unless output_name.nil? || output_name.to_s == '_'
  #       read_attribute(:outslot)
  #     end
  #     # @return Array[Hanuman::Stage] List holding the single output of this stage
  #     def outslots() [output] ; end
  #
  #     # def output(output_name=nil)
  #     #   outslot(output_name).stage
  #     # end
  #     # def set_output(output_name, stage)
  #     #   outslot(output_name).stage = stage
  #     # end
  #     # # @return Array[Hanuman::Stage] List holding the single output to this stage
  #     # def outputs()
  #     #   outslots.map(&:stage)
  #     # end
  #   end
  # end

end
