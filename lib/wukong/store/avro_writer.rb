require 'avro'

Settings.define :cassandra_avro_schema, :default => ('/usr/local/share/cassandra/interface/avro/cassandra.avpr')

class AvroWriter
  #
  # Reads in the protocol schema
  # creates the necessary encoder and writer.
  #
  def initialize
    schema_file = Settings.cassandra_avro_schema
    @proto  = Avro::Protocol.parse(File.read(schema_file))
    @schema = @proto.types.detect{|schema| schema.name == 'StreamingMutation'}
    @enc    = Avro::IO::BinaryEncoder.new($stdout)
    # @enc    = DummyEncoder.new($stdout)
    @writer = Avro::IO::DatumWriter.new(@schema)
    # warn [@schema, @enc].inspect
  end

  def write key, col_name, value
    @writer.write(smutation(key, col_name, value), @enc)
  end

  def write_directly key, col_name, value
    @enc.write_bytes(key)
    @enc.write_bytes(col_name)
    @enc.write_bytes(value)
    @enc.write_long(0)
    @enc.write_int(0)
  end

  #
  # Iterate through each key value pair in the hash to
  # be inserted and write directly one at a time
  #
  def put id, hsh
    hsh.each do |k,v|
      # write_directly(id, k, v)
      puts "Insert(row_key => #{id}, column_name => #{k}, value => #{v})"
    end
  end

  def smutation key, name, value
    {
      'key'       => key,
      'name'      => name.to_s,
      'value'     => value.to_s,
      'timestamp' => Time.epoch_microseconds,
      'ttl'       => 0
    }
  end
end
