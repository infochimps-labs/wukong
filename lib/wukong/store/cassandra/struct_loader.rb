require 'avro'

Settings.define :cassandra_avro_schema, :default => ('/usr/local/share/cassandra/interface/avro/cassandra.avpr')

module Wukong::Store::Cassandra
  class StructLoader < Wukong::Streamer::StructStreamer
    def initialize *args
      super(*args)
      @log = PeriodicMonitor.new
    end

    #
    # Blindly expects objects streaming by to have a "streaming_save" method
    #
    def process object, *_
      # object.save
      object.streaming_save
      @log.periodically(object.to_flat)
    end
  end
end
