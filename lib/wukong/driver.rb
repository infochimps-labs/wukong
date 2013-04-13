module Wukong

  # A Driver is a class including the DriverMethods module which
  # connects a Dataflow or Processor to the external world of inputs
  # and outputs.
  #
  # @example Minimal Driver class
  #
  #   class MinimalDriver
  #     include Wukong::DriverMethods
  #     def initialize(label, settings)
  #       construct_dataflow(label, settings)
  #     end
  #     def process record
  #       puts record
  #     end
  #   end
  #
  # The MinimalDriver#send_through_dataflow method can be called on an
  # instance of MinimalDriver with any input record.
  #
  # This record will be passed through the dataflow, starting from its
  # root, and each record yielded at the leaves of the dataflow will
  # be passed to the driver's #process method.
  #
  # The #process method of an implementing driver should *not* yield,
  # unlike the process method of a Processor class.  Instead, it
  # should treat its argument as an output of the dataflow and do
  # something appropriate to the driver (write to file, database,
  # terminal, &c.).
  #
  # Drivers are also responsible for implementing the lifecycle of
  # processors and dataflows they drive.  A more complete version of
  # the above driver class would:
  #
  #   * call the #setup_dataflow method when ready to trigger the
  #     Processor#setup method on each processor in the dataflow
  #
  #   * call the #finalize_dataflow method when indicating that the
  #     dataflow should consider a batch of records complete
  #
  #   * call the #finalize_and_stop_dataflow method to indicate the
  #     last batch of records and to trigger the Processor#stop method
  #     on each processor in the dataflow
  #
  # @see Wukong::Local::StdioDriver for a more complete example
  module DriverMethods

    attr_accessor :label
    attr_accessor :settings
    attr_accessor :dataflow

    # Classes including DriverMethods should override this method with
    # some way of handling the `output_record` that is appropriate for
    # the driver.
    #
    # @param [Object] output_record
    def process output_record
      raise NotImplementedError.new("Define the #{self.class}#process method to handle output records from the dataflow")
    end

    # Construct a dataflow from the given `label` and `settings`.
    #
    # This method does **not** cause Processor#setup to be called on
    # any of the processors in the dataflow.  Call the #setup_dataflow
    # method to explicitly have setup occur.  This distinction is
    # useful for drivers which themselves need to do complex
    # initialization before letting processors in the dataflow
    # initialize.
    #
    # @param [Symbol] label the name of the dataflow (or processor) to build
    # @param [Hash] settings
    # @param settings [String] :to Serialize all output via the named serializer (json, tsv)
    # @param settings [String] :from Deserialize all input via the named deserializer (json, tsv)
    # @param settings [String] :as Recordize each input as instances of the given class
    # 
    # @see #setup_dataflow
    def construct_dataflow(label, settings={})
      self.label    = label
      self.settings = settings
      prepend(:recordize)                       if settings[:as]
      prepend("from_#{settings[:from]}".to_sym) if settings[:from]
      append("to_#{settings[:to]}".to_sym)      if settings[:to]
      build_dataflow
    end

    # Walks the dataflow and calls Processor#setup on each of the
    # processors.
    def setup_dataflow
      dataflow.each_stage do |stage|
        stage.setup
      end
    end

    # Send the given `record` through the dataflow.
    #
    # @param [Object] record
    def send_through_dataflow(record)
      wiring.start_with(dataflow.root).call(record)
    end

    # Indicate a full batch of records has already been sent through
    # and any batch-oriented or accumulative operations should trigger
    # (e.g. - counting).
    #
    # Walks the dataflow calling Processor#finalize on each processor.
    #
    # On the *last* batch, the #finalize_and_stop_dataflow method
    # should be called instead.
    #
    # @see #finalize_and_stop_dataflow
    def finalize_dataflow
      dataflow.each_stage do |stage|
        stage.finalize(&wiring.advance(stage))
      end
    end

    # Works similar to #finalize_dataflow but calls Processor#stop
    # after calling Processor#finalize on each processor.
    def finalize_and_stop_dataflow
      dataflow.each_stage do |stage|
        stage.finalize(&wiring.advance(stage))
        stage.stop
      end      
    end

    protected

    # The builder for this driver's `label`, either for a Processor or
    # a Dataflow.
    #
    # @return [Wukong::ProcessorBuilder, Wukong::DataflowBuilder]
    def builder
      return @builder if @builder
      raise Wukong::Error.new("could not find definition for <#{label}>") unless Wukong.registry.registered?(label.to_sym)
      @builder = Wukong.registry.retrieve(label.to_sym)
    end

    # Return the builder for this driver's dataflow.
    #
    # Even if a Processor was originally named by this driver's
    # `label`, a DataflowBuilder will be returned here.  The
    # DataflowBuilder is itself built from just the ProcessorBuilder
    # alone.
    #
    # @return [Wukong::DataflowBuilder]
    # @see #builder
    def dataflow_builder
      @dataflow_builder ||= (builder.is_a?(DataflowBuilder) ? builder : Wukong::DataflowBuilder.receive(for_class: Class.new(Wukong::Dataflow), stages: {label.to_sym => builder}))
    end

    # Build the dataflow using the #dataflow_builder and the supplied
    # `settings`.
    #
    # @return [Wukong::Dataflow]
    def build_dataflow
      self.dataflow = dataflow_builder.build(settings)
    end

    # Add the processor with the given `new_label` in front of this
    # driver's dataflow, making it into the new root of the dataflow.
    #
    # @param [Symbol] new_label
    def prepend new_label
      raise Wukong::Error.new("could not find processor <#{new_label}> to prepend") unless Wukong.registry.registered?(new_label)
      dataflow_builder.prepend(Wukong.registry.retrieve(new_label))
    end

    # Add the processor with the given `new_label` at the end of each
    # of this driver's dataflow's leaves.
    #
    # @param [Symbol] new_label
    def append new_label
      raise Wukong::Error.new("could not find processor <#{new_label}> to append") unless Wukong.registry.registered?(new_label)
      dataflow_builder.append(Wukong.registry.retrieve(new_label))
    end

    # Returns the underlying Wiring object that will coordinate
    # transfer of records from the driver to the dataflow and back to
    # the driver.
    #
    # @return [Wiring]
    def wiring
      @wiring ||= Wiring.new(self, dataflow)
    end
    
  end

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
