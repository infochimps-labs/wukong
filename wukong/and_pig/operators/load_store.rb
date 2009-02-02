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

      #===========================================================================
      #
      #
      # The "STORE" pig imperative:
      #   STORE Relation INTO 'filename'
      # If no filename is given, the relation's name is used
      #
      def store filename=nil
        filename ||= relation
        self.class.emit "STORE #{relation} INTO '#{filename}'"
        self
      end

      # Store the relation, removing the existing file
      def store! filename=nil
        filename ||= relation
        rmf!  filename
        store filename
      end

      # Force a store to disk, then load (so all calculations proceed from there)
      def checkpoint!
        store!
        load
      end

    end
  end
end
