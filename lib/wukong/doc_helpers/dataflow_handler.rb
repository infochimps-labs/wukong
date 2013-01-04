module Wukong
  module DocHelpers

    # Handles the Wukong.dataflow syntax.
    class DataflowHandler < YARD::Handlers::Ruby::ClassHandler

      handles method_call(:dataflow)

      # :nodoc:
      def base_dataflow_class
        @base_dataflow_class ||= YARD::CodeObjects::ClassObject.new(namespace, "Wukong::Dataflow")
      end

      # :nodoc:
      def process
        dataflow_name  = statement.parameters.first.jump(:tstring_content, :ident).source
        class_name     = Gorillib::Inflector.camelize(dataflow_name)
        dataflow_class = create_class(class_name, base_dataflow_class)
        dataflow_body  = statement.last.last

        push_state(:owner => dataflow_class, :scope => :class, :namespace => dataflow_class) do
          parse_block(dataflow_body)
        end
      end
      
    end
  end
end

