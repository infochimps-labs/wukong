module Wukong
  class ProcessorBuilder < Hanuman::StageBuilder
    def namespace(*args)
      args.first.is_a?(Class) ? args.first : Wukong::Processor
    end
  end

  # The Processor is the basic unit of computation in Wukong.  A
  # processor can be thought of as an arbitrary function that takes
  # certain inputs and produces certain (or no) outputs.
  #
  # A Processor can be written and tested purely in Ruby and on your
  # local machine.  You can glue processors together
  class Processor < Hanuman::Stage
    include Logging
    include Vayacondios::Notifications
    
    field :action,   Whatever

    class << self

      def describe desc
        @description = desc
      end
      
      def description
        @description
      end
      
      def consumes(klass, options = {})
        validate_and_set_consume(klass)
        validate_and_set_serialize(:from, options)
      end

      def produces(klass, options = {})
        validate_and_set_produce(klass)
        validate_and_set_serialize(:to, options)      
      end
      
      def validate_and_set_consume klass
        @consume = klass if valid_recordizer?(klass)
      end

      def validate_and_set_produce klass
        @produce = klass if valid_recordizer?(klass)
      end
      
      def valid_recordizer? klass
        klass.instance_methods.include?(:to_primitive) && klass.respond_to?(:receive)
      end
      
      def valid_serializer? label
        %w[ tsv json xml ].include? label
      end

      def validate_and_set_serialize(direction, options)
        instance_variable_set("@serialize_#{direction}", options[direction]) if valid_serializer?(options[direction])
      end

    end
        
    def expected_record_type(type)
      self.class.instance_variable_get("@#{type}")
    end
    
    def expected_serialization(direction)
      self.class.instance_variable_get("@serialization_#{direction.to_s}")
    end

    # This is a placeholder method intended to be overridden
    def perform_action(*args) ; end 
    
    # The action attribute is turned into the perform action method
    def receive_action(action)
      self.define_singleton_method(:perform_action, &action)
    end

    # This method is called after the processor class has been instantiated
    # but before any records are given to it to process
    def setup
    end

    # This method is called once per record
    # Override this in your subclass
    def process(record, &emit)
      yield record
    end
      
    # This method is called after all records have been processed
    def stop
    end

  end
end
