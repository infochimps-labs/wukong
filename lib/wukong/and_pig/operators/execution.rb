module Wukong
  module AndPig
    class PigVar

      # ===========================================================================
      #
      # STREAM
      #
      def stream options={}
        new_in_chain klass, "STREAM #{relation}"
      end
    end
  end
end

