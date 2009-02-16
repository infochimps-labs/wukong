module Wukong
  module Streamer
    #
    # emit only some records, as dictated by the #emit? method
    #
    class Filter < Wukong::Streamer::Base

      #
      # Filter out a subset of record/lines
      #
      # Subclass and re-define the emit? method
      #
      def stream
        $stdin.each do |line|
          line.chomp!
          puts line if emit?(line)
        end
      end
    end
  end
end
