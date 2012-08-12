module Wukong
  module Streamer
    class ModelStreamer < Wukong::Streamer::Base
      class_attribute :model_klass

      def initialize
        self.model_klass = self.class.model_klass
      end

      #
      # Default recordizer: returns array of fields by splitting at tabs
      #
      def recordize line
        vals = line.split("\t")
        [@model_klass.from_tuple(*vals)]
      end

    end
  end
end
