module Wukong
  module DocHelpers

    # Handles the Wukong.processor syntax.
    class ProcessorHandler < YARD::Handlers::Ruby::ClassHandler

      handles method_call(:processor)

      # :nodoc:
      def base_processor_class
        @base_processor_class ||= YARD::CodeObjects::ClassObject.new(namespace, "Wukong::Processor")
      end

      # :nodoc:
      def process
        processor_name  = statement.parameters.first.jump(:tstring_content, :ident).source
        class_name      = Gorillib::Inflector.camelize(processor_name)
        processor_class = create_class(class_name, base_processor_class)
        processor_body  = statement.last.last
        
        push_state(:owner => processor_class, :scope => :class, :namespace => processor_class) do
          parse_block(processor_body)
        end
      end
      
    end
  end
end

