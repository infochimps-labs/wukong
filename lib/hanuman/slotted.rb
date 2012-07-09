module Hanuman

  class Source < Stage  ; end
  class Sink   < Stage  ; end

  # A stand-in source; throws an error if you try to use it
  StubSource = Stage.new(name: :stub_source)

  # A stand-in sink; throws an error if you try to use it
  StubSink   = Stage.new(name: :stub_sink) do
    define_singleton_method(:process){|*args| raise NoMethodError, "Tried to send #{args.inspect} into stub sink" }
    define_singleton_method(:inspect){|*| '<StubSink>' }
  end

  #
  # Wiring point for a stage connection
  #
  module InputSlotted
    extend Gorillib::Concern

    included do |base|
      base.field(:source,   Hanuman::Stage, default: ->{ Hanuman::StubSource }, writer: false, tester: true,
        doc: 'stage in graph that feeds into this one')
    end

    # @return [Array[Hanuman::Stage]] list of all sources this stage is connected from
    def sources() [source] ; end

    # @param stage [Hanuman::Stage] the new stage to accept input from
    def set_source(stage)
      write_attribute(:source, stage)
    end

    # wire another stage into this one
    # @param other [Hanuman::Outlinkable] the other stage
    # @returns this object, for chaining
    def <<(other)
      from(other)
      self
    end

    # wire another stage into this one
    # @param other [Hanuman::Outlinkable] the other stage
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
      base.field(:sink,     Hanuman::Stage, default:  ->{ Hanuman::StubSink }, writer: false, tester: true,
        doc: 'stage in graph this one feeds into')
    end

    # @return [Array[Hanuman::Stage]] list of all sinks this stage is connected to
    def sinks() [sink] ; end

    # @param stage [Hanuman::Stage] the new stage to target
    def set_sink(stage)
      write_attribute(:sink, stage)
    end

    # wire this stage into another one
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

  # ______________________________________________________________________
  # ______________________________________________________________________

  class InputSlot < Slot
    include InputSlotted

    def process(*args) ; stage.process_input(self.name, *args) ; end
  end

  class OutputSlot < Slot
    include Hanuman::InputSlotted
    include Hanuman::OutputSlotted

    def process(*args)
      sink.process(*args)
    rescue StandardError => err ; err.polish("#{self.graph_id}: emitting #{args.inspect} to #{sink.inspect}") rescue nil ; raise
    end
  end

  #
  # Apply slot modules to stage subtypes
  #

  Action.class_eval do
    include Hanuman::InputSlotted
    include Hanuman::OutputSlotted

    # magic(:consumed, Whatever,       default: Whatever, writer: false,
    #   doc: 'expected type for consumed data')
    # magic(:product, Whatever, default: Whatever, writer: false,
    #   doc: 'expected type for produced data')

    def input()  ; self ; end
    def output() ; self ; end
  end

  Product.class_eval do
    include Hanuman::InputSlotted
    include Hanuman::OutputSlotted
  end

  Source.class_eval do
    include OutputSlotted
  end
  Sink.class_eval do
    include InputSlotted
  end
  
end

