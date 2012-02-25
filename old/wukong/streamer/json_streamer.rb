module Wukong
  module Streamer
    #
    #
    # Note: it's on you to `require 'json'` somewhere (there's too many 
    class JsonStreamer < Wukong::Streamer::Base

      #
      # Parses the incoming record as JSON, returns a single arg to #process
      #
      def recordize line
        begin
          [JSON.parse(line)]
        rescue StandardError => boom
          bad_record!(boom, line.to_s)
        end
      end

    end
  end
end
