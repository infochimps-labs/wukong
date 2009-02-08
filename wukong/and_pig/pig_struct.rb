module Wukong
  module TypedStructMethods
    module ClassMethods
      #
      # Pig type string --
      # the pig type strings for each sub-element.
      #
      def typify
        vars_str = members.zip(mtypes).map do |attr, mtype|
          "%s: %s" % [attr, mtype.typify]
        end
        "(#{vars_str.join(', ')})"
      end

      #
      #
      #
      def pig_load filename
        Wukong::AndPig::PigVar.pig_load filename, self
      end

      # def relationize
      #   self.to_s
      # end
    end
  end
end



# module Wukong
#   module AndPig
#
#     module PigEmitter
#       module ClassMethods
#
#         def pig_rel relation
#           PigVar.new relation, self
#         end
#
#         def [] relation
#           pig_rel relation
#         end
#       end
#
#       def self.included base
#         base.extend ClassMethods
#       end
#     end
#   end
# end
