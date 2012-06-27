module Hanuman

  #
  # Provides the methods required in order to accept inbound links.
  # Including class must provide the input attribute and the owner method.
  #
  # @see IsOwnInputSlot
  # @see Slottable
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

  #
  # Provides the methods required in order to accept outbound links.
  # Including class must provide the output attribute and the owner method.
  #
  # @see IsOwnOutputSlot
  # @see Slottable
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

  class Slot
    include  Gorillib::Builder
    magic    :name,  Symbol
    magic    :stage, Hanuman::Stage
    def owner
      stage.owner
    end
    def to_key() name ; end
  end

  class InputSlot < Slot
    include  Hanuman::Inlinkable
    magic    :input,    Hanuman::Stage, :writer => false, :tester => true, :doc => 'stage/slot in graph that feeds into this one'
    def other() input ; end
  end

  class OutputSlot < Slot
    include  Hanuman::Outlinkable
    magic    :output,   Hanuman::Stage, :writer => false, :tester => true, :doc => 'stage/slot in graph this one feeds into'
    def other() ouput ; end
  end

end
