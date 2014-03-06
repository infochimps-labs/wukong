module Wukong

  # Provides a very Ruby-minded way of walking a dataflow connected to
  # a driver.
  class Wiring

    # The driver instance that likely calls the #start_with method and
    # provides a #process method to be called by this wiring.
    attr_accessor :driver

    # The dataflow being wired.
    attr_accessor :dataflow

    # Construct a new Wiring for the given `driver` and `dataflow`.
    #
    # @param [#process] driver
    # @param [Wukong::Dataflow] dataflow
    def initialize(driver, dataflow)
      @driver    = driver
      @dataflow  = dataflow
    end

    # Return a proc which, if called with a record, will process that
    # record through each of the given `stages` as well as through the
    # rest of the dataflow ahead of them.
    #
    # @param [Array<Wukong::Stage>] stages
    # @return [Proc]
    def start_with(*stages)
      to_proc.curry.call(stages)
    end

    # Return a proc (the output of #start_with) which will process
    # records through the stages that are ahead of the given stage.
    #
    # @param [Wukong::Stage] stage
    # @return [Proc]
    #
    # @see #start_with
    def advance(stage)
      # This is where the tree of procs will terminate, but only after
      # having passed all output records through the driver -- the
      # last "stage".
      return start_with() if stage.nil? || stage == driver

      # Otherwise we're still in the middle of the tree...
      descendents = dataflow.descendents(stage)
      if descendents.empty?
        # No descendents it means we've reached a leaf of the tree so
        # we'll run records through the driver to generate output.
        start_with(driver)
      else
        # Otherwise continue down the tree of procs...
        start_with(*descendents)
      end
    end
    
    # :nodoc:
    def to_proc
      return @wiring if @wiring
      @wiring = Proc.new do |stages, record|
        stages.each do |stage|
          stage.process(record, &advance(stage)) if stage
        end
      end
    end
  end
end
