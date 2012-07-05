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
      base.field(:schema, Whatever,       :default => Whatever, :writer => false,
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
      base.magic(:schema, Whatever, :default => Whatever, :writer => false,
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

  Action.class_eval do
    include Hanuman::InputSlotted
    include Hanuman::OutputSlotted

    def input()  ; self ; end
    def output() ; self ; end
  end

  Resource.class_eval do
    include Hanuman::InputSlotted
    include Hanuman::OutputSlotted
  end

  Source.class_eval do
    include OutputSlotted
  end
  Sink.class_eval do
    include InputSlotted
  end


  # class Slot
  #   include Gorillib::Builder
  #   field :name, Symbol, position: 0, doc: 'name (unique on its stage) for this slot'
  #
  #   def process(*args) ; sink.process(*args) ; end
  # end
  #
  # class InputSlot < Slot
  #   include InputSlotted
  # end
  #
  # class OututSlot < Slot
  #   include OutputSlotted
  # end

end
