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
      def self.pig_load rel, klass, options={ }
        filename = options[:filename] || default_filename(rel)
        self.set rel, self.new(klass, rel, "LOAD    '#{filename}' AS #{klass.typify(options[:has_rsrc])}")
        if options[:has_rsrc]
          lval = self[rel]
          lval.generate lval, *lval.fields
        end
        rel
      end

      #===========================================================================
      #
      #
      # The "STORE" pig imperative:
      #   STORE Relation INTO 'filename'
      # If no filename is given, the relation's name is used
      #
      def store filename=nil
        filename ||= default_filename
        self.class.emit "STORE %-19s INTO    '%s'" % [relation, filename]
        self
      end

      # Store the relation, removing the existing file
      def store! filename=nil
        filename ||= default_filename
        rmf!  filename
        mkdir File.dirname(filename)
        store filename
      end

      # Force a store to disk, then load (so all calculations proceed from there)
      def checkpoint! options={}
        options = options.reverse_merge :filename => default_filename
        store!   options[:filename]
        self.class.pig_load(self.name, klass, options)
      end

      def default_filename
        self.class.default_filename self.name
      end
      def self.default_filename name
        File.join(working_dir, name.to_s)
      end
    end
  end
end
