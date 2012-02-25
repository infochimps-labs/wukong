module Wukong
  module Streamer
    class RecordStreamer < Wukong::Streamer::Base

      #
      # Default recordizer: returns array of fields by splitting at tabs
      #
      def recordize line
        line.split("\t") rescue nil
      end

    end
  end
end
