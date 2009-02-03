module Wukong
  module AndPig

    class PigVar


      # ===========================================================================
      #
      # Pig expressions
      #

      #
      def dfs cmd, filename
        # note == no '' on path
        self.class.emit "%-23s\t           %s" % [cmd, filename]
      end
      #
      # remove the stored file
      #
      def rmf! filename
        dfs :rmf, filename
      end
    end
  end
end
