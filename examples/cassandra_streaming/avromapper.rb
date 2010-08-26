#!/usr/bin/env ruby

$: << '/home/jacob/Programming/avro/lang/ruby/lib'

require 'rubygems'
require 'avro'
require 'wukong'


Time.class_eval do
  def self.epoch_microseconds
    (Time.now.to_i * 1_000_000)
  end
end

class SmutWriter
  attr_accessor :smutation

  def initialize
    @smutation = {}
    @smutation['mutation'] = {}
    @smutation['mutation']['column_or_supercolumn'] = {}
    @smutation['mutation']['column_or_supercolumn']['column'] = {}
  end

  def avro_connection
    @avro_connection ||= AvroConnector.new('cassandra.avpr')
  end

  def write key, value
    @smutation['key'] = key
    @smutation['mutation']['column_or_supercolumn']['column'] = new_column('count', value)
    avro_connection.write(smutation)
  end

  def new_column name, value
    column = {
      'name'  => name.to_s,
      'value' => value.to_s,
      'clock' => {'timestamp' => Time.epoch_microseconds},
      'ttl'   => 0
    }
    column
  end

end

#
# Sets up avro, reads in schema
#
class AvroConnector

  def initialize rpc_protocol
    @proto  = Avro::Protocol.parse(File.read(rpc_protocol))
    @schema = @proto.types.select{|schema| schema.name == 'StreamingMutation'}.first
    @enc    = Avro::IO::BinaryEncoder.new($stdout)
    @writer = Avro::IO::DatumWriter.new(@schema)
  end

  def write smutation
    @writer.write(smutation, @enc)
  end

end

class AvroStreamer < Wukong::Streamer::RecordStreamer

  def initialize *args
    super(*args)
    @smut_writer = SmutWriter.new
  end

  def process word, count, *_
    @smut_writer.write(word, count)
  end

end

Wukong::Script.new(AvroStreamer, nil).run
