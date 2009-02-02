
module Wukong
  module AndPig

    class PigVar


      # ===========================================================================
      #
      # Pig expressions
      #

      #
      def dfs cmd, path
        # note == no '' on path
        emit "%-23s\t        %s" % [cmd, path]
      end
      #
      # remove the stored file
      #
      def rmf!
        dfs :rmf, path
      end
    end
  end
end
