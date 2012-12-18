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
      
      def consumes(*args)
        options   = args.extract_options!
        @consumes = options[:as]
        validate_and_set_serialization(:from, args.first)
      end

      def produces(*args)
        options   = args.extract_options!
        @produces = options[:as]
        validate_and_set_serialization(:to, args.first)      
      end
            
      def valid_serializer? label
        label
      end

      def validate_and_set_serialization(direction, label)
        instance_variable_set("@serialization_#{direction}", label) if %w[ tsv json xml ].include?(label.to_s)
      end

      def configure(settings)
        fields.each_pair do |name, field|
          field_props = {}.tap do |props|
            props[:description] = field.doc unless field.doc == "#{name} field"
            props[:type]        = field.type.product
          end
          settings.define(name, field_props)
        end
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

    # This method is called to signal the last record has been
    # received but that further processing may still be done, events
    # still be yielded, &c.
    #
    # This can be used within an aggregating processor (like a reducer
    # in a map/reduce job) to start processing the final aggregate of
    # records since the "last record" has already been received.
    def finalize
    end

    # This method is called after all records have been passed.  It
    # signals that processing should stop.
      
    # This method is called after all records have been processed
    def stop
    end

  end
end
