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

      def for_gen *args
        l_klass = Struct.new(*args)
        new_in_chain l_klass, "FOREACH #{relation} GENERATE #{args.join(",")}"
      end

    end
  end
end
