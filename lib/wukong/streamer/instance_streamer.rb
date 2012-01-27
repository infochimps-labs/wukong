module Wukong
  module Streamer
    #
    # Instantiate an instance of 'record_model' for each line
    class InstanceStreamer < Wukong::Streamer::RecordStreamer
      class_attribute :record_model

      def recordize(raw_record)
        fields = super(raw_record)
        [ record_model.new(*fields) ] if fields
      end

    end
  end
end
