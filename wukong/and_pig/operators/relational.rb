# == RelationalOperators
#
# GROUP, COGROUP, JOIN see groupies.rb
# CROSS see

# distinct
# filter
# limit
# order
# split
# union

#
# stream
# load
# store
#
module Wukong
  module AndPig
    class PigVar

      # ===========================================================================
      #
      # CROSS
      #
      def cross
        new_in_chain klass, "CROSS #{relation}"
      end

      # ===========================================================================
      #
      # DISTINCT
      #
      def DISTINCT
        new_in_chain klass, "DISTINCT #{relation}"
      end

      # ===========================================================================
      #
      # FILTER
      #
      def FILTER
        new_in_chain klass, "FILTER #{relation}"
      end

      # ===========================================================================
      #
      # LIMIT
      #
      def limit
        new_in_chain klass, "LIMIT #{relation}"
      end

      # ===========================================================================
      #
      # LOAD
      #
      def load
        new_in_chain klass, "LOAD #{relation}"
      end

      # ===========================================================================
      #
      # ORDER
      #
      def order
        new_in_chain klass, "ORDER #{relation}"
      end

      # ===========================================================================
      #
      # SPLIT
      #
      def SPLIT
        new_in_chain klass, "SPLIT #{relation}"
      end

      # ===========================================================================
      #
      # STORE
      #
      def store
        new_in_chain klass, "STORE #{relation}"
      end

      # ===========================================================================
      #
      # STREAM
      #
      def stream
        new_in_chain klass, "STREAM #{relation}"
      end

      # ===========================================================================
      #
      # UNION
      #
      def union
        new_in_chain klass, "UNION #{relation}"
      end

    end
  end
end
