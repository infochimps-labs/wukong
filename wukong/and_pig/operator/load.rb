# == Load/StoreFunctions ==
# BinaryDeserializer
# BinarySerializer
# BinStorage
# PigStorage
# PigDump
# TextLoader

module Wukong
  module AndPig
    class PigVar
      #===========================================================================
      #
      # The "LOAD" pig expression:
      #   MyRelation = LOAD 'my_relation.tsv' AS (attr_a: int, attr_b: chararray) ;
      #
      # The AS type spec is generated from klass
      #
      def self.load filename, klass
        relation = filename.gsub(/\..*$/, '').gsub(/\W+/, '_').to_sym
        self.new klass, relation, 0, "LOAD '#{filename}' AS #{type_spec(klass)}"
      end
    end
  end
end
