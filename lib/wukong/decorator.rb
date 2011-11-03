require 'java'

java_import 'com.cloudera.flume.core.Event'
java_import 'com.cloudera.flume.core.EventImpl'
java_import 'com.cloudera.flume.core.EventSinkDecorator'

module Wukong 
  class Decorator < EventSinkDecorator

    def initialize(mapper, reducer=nil, options={})
      super(nil)
      @mapper = mapper.new
    end

    def append(e)
      line   = String.from_java_bytes(e.getBody)
      record = @mapper.recordize(line.chomp)
      @mapper.process(*record) do |output|
        processed = output.to_flat.join("\t")
        event     = EventImpl.new(processed.to_java_bytes, e.getTimestamp, e.getPriority, e.getNanos, e.getHost, e.getAttrs)
        super event
      end
    end

    def run() self ; end

  end
end
