module Wukong
  module Streamer
    class LineStreamer < Wukong::Streamer::Base
      #
      # Turns a flat line into a record for +#process+ to consume
      #
      def recordize line
        [line]
      end
    end
  end
end
