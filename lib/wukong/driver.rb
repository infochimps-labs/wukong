module Wukong
  module DriverMethods

    def driver
      @driver ||= Driver.new(dataflow)
    end

    def lookup(label)
      raise "could not find definition for #{label}" unless Wukong.registry.registered?(label.to_sym)
      Wukong.registry.retrieve(label.to_sym)
    end
    
    def lookup_and_build(label, options = {})
      lookup(label).build(options)
    end
    
    def build_serializer(direction, label)
      lookup_and_build("#{direction}_#{label}")
    end

    def add_serialization(dataflow, direction, label)
      case direction
      when :to   then dataflow.push    build_serializer(direction, label)
      when :from then dataflow.unshift build_serializer(direction, label)
      end
    end

    def setup_dataflow
      dataflow.each(&:setup)
    end

    def finalize_and_stop_dataflow
      dataflow.each do |stage|
        stage.finalize(&driver.start_with(stage)) if stage.respond_to?(:finalize)
        stage.stop
      end      
    end

    # So pretty...
    def construct_dataflow(label, options)
      dataflow = lookup_and_build(label, options)
      dataflow = dataflow.respond_to?(:stages) ? dataflow.directed_sort.map{ |name| dataflow.stages[name] } : [ dataflow ]
      expected_input_model  = (options[:consumes].constantize rescue nil)    || dataflow.first.expected_record_type(:consumes)
      dataflow.unshift lookup_and_build(:recordize, model: expected_input_model)  if expected_input_model
      expected_output_model = (options[:produces].constantize rescue nil)    || dataflow.first.expected_record_type(:produces)
      dataflow.push lookup_and_build(:recordize, model: expected_output_model)    if expected_output_model
      expected_input_serialization  = options[:from] || dataflow.last.expected_serialization(:from)
      add_serialization(dataflow, :from, expected_input_serialization)            if expected_input_serialization
      expected_output_serialization = options[:to]   || dataflow.last.expected_serialization(:to)
      add_serialization(dataflow, :to, expected_output_serialization)             if expected_output_serialization
      dataflow.push self
    end    
  end

  class Driver
    attr_accessor :dataflow

    def initialize(dataflow)
      @dataflow = dataflow
    end

    def to_proc
      return @wiring if @wiring
      @wiring = Proc.new do |stage, record|
        stage.process(record, &advance(stage)) if stage          
      end
    end

    def send_through_dataflow(record)
      start_with(dataflow.first).call(record)
    end
    
    def start_with(stage)
      to_proc.curry.call(stage)
    end

    def advance(stage)
      next_stage = stage_iterator(stage)
      start_with(next_stage)
    end

    # This should properly be defined on dataflow/builder
    def stage_iterator(stage)
      position = dataflow.find_index(stage)
      dataflow[position + 1]    
    end 

    def call(*args)
      to_proc.call(*args)
    end
    
  end
end
