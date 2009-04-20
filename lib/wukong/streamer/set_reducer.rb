require 'wukong/streamer/list_reducer'
module Wukong
  module Streamer
    #
    # Emit each unique key and the count of its occurrences
    #
    class SetReducer < Wukong::Streamer::ListReducer
      # Begin with an empty set
      def start! *args
        self.values = Set.new
      end
    end
  end
end
