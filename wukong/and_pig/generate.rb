require 'wukong/and_pig/generate/variable_inflections'

module Wukong
  module AndPig
    PIG_SYMBOLS = { }
    #
    # All the embarrassing magick to pretend ruby symbols are pig relations
    #
    class PigVar

      # def emit cmd
      #   puts cmd + ';'
      #   self
      # end
      #
      # def emit_set var, cmd
      #   emit "%-23s\t= %s" % [var, cmd]
      # end

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



module Wukong
  module AndPig
    #
    # Load the main class definitions
    #
    def self.init_load
      puts File.open(PIG_DEFS_DIR+"/init_load.pig").read
    end

    class AS
      def self.[] klass
        klass.as
      end
    end

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

        #
        # OK we're going to cheat here:
        # just cat the file in, and treat it as a scalar
        #
        def load_scalar path
          # var = `hadoop dfs -cat '#{path}/part-*' | head -n1 `.chomp
          var = "636"

        end
      end



      def self.included base
        base.extend ClassMethods
      end
    end
  end
end
