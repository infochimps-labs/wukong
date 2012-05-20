module Hanuman

  #
  # Slot holds the
  #
  class Slot
    include Gorillib::Model
    field  :name, Symbol

    def initialize(name=:_)
      self.receive_name(name)
    end

    # def process(*args)
    #   stage.process(*args)
    # end
    # field  :stage, Hanuman::Stage, :writer => true
  end

  class Stage
    module SingleInput
      extend Gorillib::Concern
      included do
        field   :inslot,   Hanuman::Slot,  :default => Slot.new(:_), :doc => 'stage(s) in graph that feed into this one', :reader => false
        field   :input,    Hanuman::Stage,                           :doc => 'stage(s) in graph that feed into this one', :reader => false, :writer => true
      end

      def input(input_name=nil)
        raise ArgumentError, "Processors have only one input" unless input_name.nil? || input_name.to_s == '_'
        read_attribute(:input)
      end
      def set_input(input_name, stage)
        raise ArgumentError, "Processors have only one input" unless input_name.to_s == '_'
        self.input = stage
      end
      def inputs() [input] end

      # @return Array[Hanuman::Stage] The input to this stage
      def inslot(input_name=nil)
        raise ArgumentError, "Processors have only one input" unless input_name.nil? || input_name.to_s == '_'
        read_attribute(:inslot)
      end
      def inslots() [inslot] ; end

      # # @return [Hanuman::Stage] Stage that feeds into the given input slot
      # def input(input_name=nil)
      #   inslot(input_name).stage
      # end
      # def set_input(input_name, stage)
      #   inslot(input_name).stage = stage
      # end
      # # @return Array[Hanuman::Stage] List holding the inputs to this stage
      # def inputs()
      #   inslots.map(&:stage)
      # end
    end

    module SingleOutput
      extend Gorillib::Concern
      included do
        field :outslot,  Hanuman::Slot,  :default => Slot.new(:_), :doc => 'stage(s) in graph this one feeds into', :reader => false
        field   :output,   Hanuman::Stage,                           :doc => 'stage(s) in graph this one feeds into', :reader => false, :writer => true
      end

      def output(output_name=nil)
        raise ArgumentError, "Processors have only one output" unless output_name.nil? || output_name.to_s == '_'
        read_attribute(:output)
      end
      def set_output(output_name, stage)
        raise ArgumentError, "Processors have only one output" unless output_name.to_s == '_'
        self.output = stage
      end
      def outputs() [output] end

      # @return Array[Hanuman::Stage] The output of this stage
      def outslot(output_name=nil)
        raise ArgumentError, "#{self} does not have an output slot named #{output_name}" unless output_name.nil? || output_name.to_s == '_'
        read_attribute(:outslot)
      end
      # @return Array[Hanuman::Stage] List holding the single output of this stage
      def outslots() [output] ; end

      # def output(output_name=nil)
      #   outslot(output_name).stage
      # end
      # def set_output(output_name, stage)
      #   outslot(output_name).stage = stage
      # end
      # # @return Array[Hanuman::Stage] List holding the single output to this stage
      # def outputs()
      #   outslots.map(&:stage)
      # end
    end
  end

end
