module Monkeyshines
  module Store
    class NullStore < Monkeyshines::Store::Base

      def each *args, &block
      end


      # Does nothing!
      def set *args
      end

    end
  end
end
