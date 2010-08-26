#!/usr/bin/env ruby

#
# To install
#   cd avro/lang/ruby ;  sudo gem install pkg/avro-1.4.0.pre1.gem

require 'rubygems'
require 'avro'
require 'wukong'
require 'wukong/periodic_monitor'

Settings.define :cassandra_avro_schema, :default => (File.dirname(__FILE__)+'/cassandra.avpr')
Settings.define :cassandra_thrift_uri,  :default => `hostname`.chomp.strip+':9160'
Settings.define :action, :description => 'thrift or avro', :default => 'avro'

class AvroStreamer < Wukong::Streamer::RecordStreamer
  def initialize *args
    super(*args)
    case Settings.action
    when 'avro'   then @writer = SmutWriter.new
    when 'thrift' then @writer = ThriftWriter.new
    else               raise "Please name an output format, like avro or trhift (got '#{Settings.action}')" ; end
    @log = PeriodicMonitor.new
  end

  def process word, count, *_
    @writer.write(word, count)
    @log.periodically( word, count )
  end

end

#
# Avro stuff
#

Time.class_eval do
  def self.epoch_microseconds
    (Time.now.utc.to_i * 1_000_000)
  end
end

# class Avro::Schema
#   def self.validate *args
#     warn ['validate', *args]
#     true
#   end
# end

class ThriftWriter
  def initialize
    require 'cassandra/0.7'
  end
  def db
    @db ||= Cassandra.new('soc_net_tw', Settings.cassandra_thrift_uri)
  end
  def write key, value
    db.insert :Wordbag, key.to_s, 'count' => value.to_s
  end
end

class SmutWriter
  def avro_connection
    @avro_connection ||= AvroConnector.new(Settings.cassandra_avro_schema)
  end

  def write key, value
    avro_connection.write(smutation(key, 'count', value))
  end

  def smutation key, name, value
    {
      'key'      => key,
      'mutation' => { 'column_or_supercolumn' => { 'column' => {
            'name'  => name.to_s,
            'value' => value.to_s,
            'clock' => { 'timestamp' => 2 }, #  Time.epoch_microseconds },
            'ttl'   => 0
          }}}
    }
  end
end

#
# Sets up avro, reads in schema
#
class AvroConnector
  #
  # Reads in the protocol schema
  # creates the necessary encoder and writer.
  #
  def initialize schema_file
    @proto  = Avro::Protocol.parse(File.read(schema_file))
    @schema = @proto.types.detect{|schema| schema.name == 'StreamingMutation'}
    @enc    = Avro::IO::BinaryEncoder.new($stdout)
    @writer = Avro::IO::DatumWriter.new(@schema)
    # warn [@schema, @enc].inspect
  end

  def write smutation
    @writer.write(smutation, @enc)
  end
end

Wukong::Script.new(AvroStreamer, nil).run
