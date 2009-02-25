#
# The FOREACH relational operator
#
module Wukong
  module AndPig
    class PigVar
      #
      # Select all elements in the source relation that match on the selecting relation,
      # creating a relation with the same type as the source relation.
      #
      # For example, 
      #
      #   PV.isolate :isolated_cvals, :my_ids, :id, :my_complicated_values, :id
      #
      # returns a relation IsolatedCvals, whose type is identical to
      # MyComplicatedValues' type, with only the elements having an id also
      # presend in MyIds.
      #
      #
      def self.isolate lval, on, on_field, from, from_field, options={ }
        joined   = join anon(lval), on => on_field, from => from_field, :parallel => options.delete(:parallel)
        isolated = joined.generate lval, *PV[from].fields.map{|field| [from, field]}
        isolated.klass = from.klass
        isolated
      end

    end
  end
end
