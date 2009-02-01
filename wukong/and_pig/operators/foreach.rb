#
# The FOREACH relational operator
#
module Wukong
  module AndPig
    class PigVar

      # ===========================================================================
      #
      # FOREACH
      #
      def foreach
        new_in_chain klass, "FOREACH #{relation}"
      end

    end
  end
end
