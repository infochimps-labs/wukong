module Wukong
  module Streamer
    #
    # emit only some records, as dictated by the #emit? method
    #
    # This is a mixin: including this module in your streamer
    # implements its +#process+ method.
    #
    module Filter
      #
      # Filter out a subset of record/lines
      #
      # Subclass and re-define the emit? method
      #
      def process *record
        yield record if emit?(*record)
      end
    end
  end
end
