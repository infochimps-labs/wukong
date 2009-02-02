require 'wukong/and_pig/generate/variable_inflections'

module Wukong
  module AndPig
    PIG_SYMBOLS = { }
    #
    # All the embarrassing magick to pretend ruby symbols are pig relations
    #
    class PigVar
      # Output a command
      def self.emit cmd
        puts cmd + ' ;'
      end

      # generate the code
      def self.emit_setter relation, rval
        emit "%-23s\t= %s" % [relation, rval.cmd]
        relation
      end
    end
  end
end



module Wukong
  module AndPig

    module PigEmitter
      module ClassMethods

        def as
          members.zip(mtypes).map do |attr, mtype|
            "%s: %s" % [attr, mtype.typify]
          end.join(',')
        end

        def pig_rel relation
          PigVar.new relation, self
        end

        def [] relation
          pig_rel relation
        end
      end

      def self.included base
        base.extend ClassMethods
      end
    end
  end
end
