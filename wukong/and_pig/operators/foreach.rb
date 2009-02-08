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
            field_attrs << [field_spec, klass.members_types[field_spec]];
          when Array
            unless [2,3].include?(field_spec.length) then raise "Complex fields must be (field_spec, as_name) or (field_spec, as_name, as_type)" end
            field_expr, field_attr, field_type = field_spec
            field_as   = field_attr.is_a?(Array) ? "(#{field_attr.join(", ")})" : field_attr
            field_exprs << "#{field_expr} AS #{field_as}"
            field_attrs << [field_attr, field_type || klass.members_types[field_expr]]
          else raise "Don't know how to specify type for #{field_specs.inspect}"
          end
        end
        [ field_exprs, field_attrs ]
      end

      def prelimify *field_specs
        field_exprs = []
        field_attrs = []
        field_specs.map do |field_spec|
          unless field_spec.length == 2 then raise "Complex fields must be a pair (field_spec, as_name)" end
          field_expr, field_attr = field_spec
          field_exprs << "#{field_expr}"
          field_attrs += [field_attr].flatten
        end
        [ field_exprs, field_attrs ]
      end

      def generate *args
        field_exprs, field_attrs = fieldify *args
        l_klass = TypedStruct.new(*field_attrs)
        new_in_chain l_klass, "FOREACH  #{relation} GENERATE\n    #{field_exprs.join(",\n    ")}"
      end

      def foreach *args
        generate_clause = args.pop
        prelim_exprs, prelim_attrs = prelimify *args
        prelims = prelim_exprs.zip(prelim_attrs).map{|e,a| "#{a} = #{e}" }.join(";\n    ")+";"
        field_exprs, field_attrs   = fieldify *generate_clause
        l_klass = TypedStruct.new(*field_attrs)
        new_in_chain l_klass, %Q{FOREACH  #{relation} {\n    #{prelims}\n  GENERATE\n    #{field_exprs.join(",\n    ")} ; } }

      end

    end
  end
end
