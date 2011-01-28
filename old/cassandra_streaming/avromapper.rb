#!/usr/bin/env ruby

# To install avro gem
#   cd avro/lang/ruby ; gem package ; sudo gem install pkg/avro-1.4.0.pre1.gem

require 'rubygems'
require 'avro'
require 'wukong'
require 'wukong/periodic_monitor'

Settings.define :cassandra_avro_schema, :default => ('/usr/local/share/cassandra/interface/avro/cassandra.avpr')
Settings.define :cassandra_thrift_uri,  :default => `hostname`.chomp.strip+':9160'
Settings.define :log_interval, :default => 10_000

class AvroStreamer < Wukong::Streamer::RecordStreamer
  def initialize *args
    super(*args)
    @writer = SmutWriter.new
    @log = PeriodicMonitor.new
  end

  def process word, count, *_
    @writer.write_directly(word, 'count', count)
    @log.periodically( word, count )
  end
end

class SmutWriter
  # Reads in the protocol schema
  # creates the necessary encoder and writer.
  def initialize
    schema_file = Settings.cassandra_avro_schema
    @proto  = Avro::Protocol.parse(File.read(schema_file))
    @schema = @proto.types.detect{|schema| schema.name == 'StreamingMutation'}
    @enc    = Avro::IO::BinaryEncoder.new($stdout)
    @writer = Avro::IO::DatumWriter.new(@schema)
  end

  # Directly write the simplified StreamingMutation schema; uses patch from @stuhood
  def write_directly key, col_name, value
    @enc.write_bytes(key)
    @enc.write_bytes(col_name)
    @enc.write_bytes(value)
    @enc.write_long(Time.epoch_microseconds)
    @enc.write_int(0)
  end

  # Write using the datumwriter
  def write key, col_name, value
    @writer.write(smutation(key, col_name, value), @enc)
  end

  # Simplified StreamingMutation schema uses patch from @stuhood
  def smutation key, name, value
    {
      'key'       => key,
      'name'      => name.to_s,
      'value'     => value.to_s,
      'timestamp' => Time.epoch_microseconds,
      'ttl'       => 0
    }
  end

  # The StreamingMutation schema defined in trunk.
  # Becomes monstrously inefficient due to implementation of unions.
  def smutation_from_trunk key, name, value
    {
      'key'      => key,
      'mutation' => { 'column_or_supercolumn' => { 'column' => {
            'name'  => name.to_s,
            'value' => value.to_s,
            'clock' => { 'timestamp' => Time.epoch_microseconds },
            'ttl'   => 0
          }}}
    }
  end
end

Time.class_eval do
  def self.epoch_microseconds
    (Time.now.utc.to_i * 1_000_000)
  end
end

Wukong::Script.new(AvroStreamer, nil, :map_speculative => false).run
