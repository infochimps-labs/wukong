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
      def generate lval,  *field_spec
        gen_clauses = field_spec.map{|field_spec| parse_gen_clause(field_spec)}
        l_klass     = TypedStruct.new(* gen_clauses.map(&:name_type))
        l_cmd       = "FOREACH  #{self.relation} GENERATE\n  #{gen_clauses.join(",\n  ")}"
        new_in_chain(lval, l_klass, l_cmd)
      end

      #
      # for a list of GENERATE args, we need
      #
      # * gen_clauses, the clause to stuff into the GENERATE line
      #     gen_expr AS gen_field_name: gen_field_type
      #
      # * new_types, the resulting types for each
      #
      # gen_expr common cases include
      #
      #   field
      #   Rel::field
      #   Rel.(field)
      #   "ComplicatedExpression"
      #
      #
      # field_attrs
      #
      #
      def parse_gen_clause field_spec
        case field_spec
        when AS
          field_spec
        when Symbol
          AS[field_spec, field_spec, field_type(field_spec)];
        when Array
          alias_in, field_in, name, type = field_spec
          name      ||= field_in
          type        = alias_in.field_type(field_in)
          AS[field_in, name, type, alias_in]
        when Hash
          field_in, field_out = field_spec.to_a.first
          AS[field_in, field_out, field_type(field_in)]
        else raise "Don't know how to specify type for #{field_specs.inspect}"
        end
      end
    end
  end
end







          # # when Array
          # #   unless [2,3].include?(field_spec.length) then raise "Complex fields must be (field_spec, as_name) or (field_spec, as_name, as_type)" end
          # #   field_expr, field_attr, field_type = field_spec
          # #   field_as   = field_attr.is_a?(Array) ? "(#{field_attr.join(", ")})" : field_attr
          # #   gen_clauses << "#{field_expr} AS #{field_as}"
          # #   field_attrs << [field_attr, field_type || klass.members_types[field_expr]]

      # def prelimify *field_specs
      #   gen_clauses = []
      #   field_attrs = []
      #   field_specs.map do |field_spec|
      #     unless field_spec.length == 2 then raise "Complex fields must be a pair (field_spec, as_name)" end
      #     field_expr, field_attr = field_spec
      #     gen_clauses << "#{field_expr}"
      #     field_attrs += [field_attr].flatten
      #   end
      #   [ gen_clauses, field_attrs ]
      # end
      #
      # # def generate *args
      # #   gen_clauses, field_attrs = self.class.fieldify *args
      # #   l_klass = TypedStruct.new(*field_attrs)
      # #   new_in_chain l_klass, "FOREACH  #{relation} GENERATE\n    #{gen_clauses.join(",\n    ")}"
      # # end
      #
      # def foreach *args
      #   generate_clause = args.pop
      #   prelim_exprs, prelim_attrs = prelimify *args
      #   prelims = prelim_exprs.zip(prelim_attrs).map{|e,a| "#{a} = #{e}" }.join(";\n    ")+";"
      #   gen_clauses, field_attrs   = fieldify *generate_clause
      #   l_klass = TypedStruct.new(*field_attrs)
      #   new_in_chain l_klass, %Q{FOREACH  #{relation} {\n    #{prelims}\n  GENERATE\n    #{gen_clauses.join(",\n    ")} ; } }
      # end
