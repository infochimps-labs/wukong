#
# The FOREACH relational operator
#
module Wukong
  module AndPig
    class PigVar

      # ===========================================================================
      #
      # FOREACH
      #
      def foreach
        new_in_chain klass, "FOREACH  #{relation}"
      end

      def fieldify *field_specs
        field_exprs = []
        field_attrs = []
        field_specs.map do |field_spec|
          case field_spec
          when Symbol
            field_exprs << field_spec.to_s;
            field_attrs << field_spec;
          when Array
            unless field_spec.length == 2 then raise "Complex fields must be a pair (field_spec, as_name)" end
            field_expr, field_attr = field_spec
            field_exprs << "#{field_expr} AS #{field_attr.to_s}"
            field_attrs << field_attr
          else raise "Don't know how to specify type for #{field_specs.inspect}"
          end
        end
        [ field_exprs, field_attrs ]
      end

      def generate *args
        field_exprs, field_attrs = fieldify *args
        l_klass = Struct.new(*field_attrs)
        new_in_chain l_klass, "FOREACH  #{relation} GENERATE #{field_exprs.join(", ")}"
      end

    end
  end
end
