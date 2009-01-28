require 'wukong/and_pig/variable_inflections'
require 'wukong/and_pig/pig_var'

PIG_VARS = { }

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

# module TwitterFriends::StructModel
#   class << Tweet
#     attr_accessor :member_types
#     self.member_types = [ :chararray, :int, :long, :int, :int, :int, :int, :int, :chararray, :chararray ]
#   end
#
# end

class ScalarInteger  < TypedStruct.new [
    [:count,    Integer  ],
  ]
  include Wukong::AndPig::PigEmitter
  def self.load_scalar path
    var = super path
    var.to_i
  end
end
