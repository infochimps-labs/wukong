# == DiagnosticOperators
# describe
# dump
# explain
# illustrate
# == UDFStatements
# define
# register

module Wukong
  module AndPig
    class PigVar
      # DESCRIBE pig imperative
      def describe()   simple_operation :describe    end

      # DUMP pig imperative
      def dump()       simple_operation :dump        end

      # EXPLAIN pig imperative
      def explain()    simple_operation :explain     end

      # ILLUSTRATE pig imperative
      def illustrate() simple_operation :illustrate  end

    end
  end
end
