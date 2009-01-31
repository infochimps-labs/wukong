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
    end
  end
end
