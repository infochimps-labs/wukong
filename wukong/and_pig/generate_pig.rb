
module Wukong
  module AndPig
    PIG_SYMBOLS = { }
    #
    # All the embarrassing magick to pretend ruby symbols are pig relations
    #
    class PigVar
      def self.emit cmd
        puts cmd + ' ;'
      end

      # generate the code
      def self.emit_setter relation, rval
        emit "%-23s\t= %s" % [relation, rval]
        relation
      end
    end
  end
end
