module Wukong
  class EventMetadata
    include Gorillib::Model

    field :timestamp, Time,   :doc => "time the event originated, assigned by the origin (as anything they like) and unchanged afterwards. A UTC ruby time, serialized as a unix timestamp. Corresponds to Flume's `time` metadata"
    field :origin,    String, :doc => "name for the source of this record; in flume, the dispatching `host`. This influences delivery guarantees. A downcased, dasherized, dot-separated identifier."
    field :nano_ctr,  Bignum, :doc => "nanosecond timestamp, monotonically-increasing within each origin. The `[origin, nano_ctr]` pair may be considered globally unique. Serialized as whatever flume uses."

    field :topic,     Symbol, :doc => "Topic this event belongs to"

    def event_id
      [origin, nano_ctr].join('!')
    end

  end

  module Event
    extend  Gorillib::Concern
    include Gorillib::Model

    def _metadata
      @_metadata ||= {}
    end

    def _metadata= m
      @_metadata = m
    end

    def to_wire options={}
      super(options).merge(:_metadata => self._metadata)
    end
  end

end

#
# Example Usage
#
# def process(blob)
#   record   = JSON.parse(blob)
#   metadata = blob._metadata
#   { :_id => metadata.event_id, :time => metadata.timestamp, :type => metadata.topic, :data => record }
#   # ... now do stuff
# end
