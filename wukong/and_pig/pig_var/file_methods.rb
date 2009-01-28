
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

      # Store the relation to its file
      def store
        emit "STORE %-17s\t  INTO '%s'" % [relation, path]
      end

      # Store the relation, removing the existing file
      def store!
        rmf!
        store
      end

      # Load from its file
      def load
        emit_set relation, "LOAD '%s' AS (%s)" % [path, AS[klass]]
      end

      # Force a store to disk, then load (so all calculations proceed from there)
      def checkpoint!
        store!
        load
      end
    end
  end
end
