module Wukong
  module DocHelpers

    # Handles the syntax
    #
    #     class Foo
    #       include Gorillib::Model
    #       field :bar, Integer, :default => 3
    #     end
    class FieldHandler < YARD::Handlers::Ruby::ClassHandler

      handles method_call(:field)
      namespace_only

      def process
        register(getter)
        register(setter)
        namespace.attributes[:instance][field_name] = { :read => getter, :write => setter }
      end
      
      def getter
        @getter ||= YARD::CodeObjects::MethodObject.new(namespace, field_name, :instance).tap do |method|
          method.docstring = getter_docstring
        end
      end

      def setter
        @setter ||= YARD::CodeObjects::MethodObject.new(namespace, field_name + '=', :instance).tap do |method|
          method.docstring = setter_docstring
        end
      end

      def getter_docstring
        doc = "@return [#{field_type}]"
        doc += " #{field_doc}"                if field_doc
        doc += " [Default: #{field_default}]" if field_default
        doc
      end

      def setter_docstring
        doc = "@return [#{field_type}]"
        doc += " #{field_doc}"                if field_doc
        doc += " [Default: #{field_default}]" if field_default
        doc
      end

      def field_name
        statement.parameters.first.jump(:tstring_content, :ident).source
      end

      def field_type
        statement.parameters[1].jump(:string_content, :ident).source
      end
      
      def field_options
        return @field_options if @field_options
        @field_options = {}
        field_options_obj = statement.parameters[2]
        if field_options_obj
          keys_and_values = field_options_obj.jump(:assoc)
          until keys_and_values.empty?
            obj = keys_and_values.shift
            if obj.type == :symbol_literal
              key   = obj.source.to_s.gsub(/^:/,'').to_sym
              value_obj = keys_and_values.shift
              if value_obj
                value = case key
                        when :doc then value_obj.source.to_s.gsub(/^"/,'').gsub(/"$/,'')
                        else
                          value_obj.source
                        end
                @field_options[key] = value
              end
            end
          end
        end
        @field_options
      end

      def field_doc
        field_options[:doc]
      end

      def field_default
        field_options[:default]
      end
        
    end
  end
end

