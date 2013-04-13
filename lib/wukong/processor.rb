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
    
    field :action, Whatever, :doc => false

    class << self

      def description desc=nil
        @description = desc if desc
        @description
      end
            
      def configure(settings)
        settings.description = description if description
        fields.each_pair do |name, field|
          next if field.doc == false || field.doc.to_s == 'false'
          next if [:log].include?(name)
          field_props = {}.tap do |props|
            props[:description] = field.doc unless field.doc == "#{name} field"
            field_type = (field.type.respond_to?(:product) ? field.type.product : field.type)
            configliere_type = case field_type
            when String                then nil
            when TrueClass, FalseClass then :boolean
            else field_type
            end
            
            props[:type]        = configliere_type if configliere_type
            props[:default]     = field.default if field.default
          end
          existing_value = settings[name]
          settings.define(name, field_props)
          settings[name] = existing_value unless existing_value.nil?
        end
      end

    end
        
    # When instantiated with a block, the block will replace this
    # method.
    #
    # @param [Array<Object>] args
    # @yield record a record that might be yielded by the block
    # @yieldparam [Object] record the yielded record
    def perform_action(*args)
    end 
    
    # :nodoc:
    #
    # The action attribute is turned into the perform action method.
    #
    # @param [Proc] action
    def receive_action(action)
      self.define_singleton_method(:perform_action, &action)
    end

    # This method is called after the processor class has been
    # instantiated but before any records are given to it to process.
    #
    # Override this method in your subclass.
    def setup
    end

    # This method is called once per record.
    #
    # Override this method in your subclass.
    #
    # @param [Object] record
    # @yield record the record you want to yield
    # @yieldparam [Object] record the yielded record
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
    #
    # Override this method in your subclass
    #
    # @yield record the record you want to yield
    # @yieldparam [Object] record the yielded record
    def finalize
    end

    # This method is called after all records have been passed.  It
    # signals that processing should stop.
    #
    # Override this method in your subclass.
    def stop
    end

  end
end
