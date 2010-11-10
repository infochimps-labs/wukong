require 'avro'

Settings.define :cassandra_avro_schema, :default => ('/usr/local/share/cassandra/interface/avro/cassandra.avpr')
module Wukong::Store::CassandraModel

  #
  # Store model using avro writer
  #
  def streaming_save
    self.class.streaming_insert id, self
  end
  module ClassMethods

    def streaming_writer
      @streaming_writer ||= AvroWriter.new
    end

    #
    # Use avro and stream into cassandra
    #
    def streaming_insert id, hsh
      streaming_writer.put(id.to_s, hsh.to_db_hash)
    end
  end
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

    def write_directly key, col_name, value, timestamp, ttl
      # Log.info "Insert(row_key => #{key}, col_name => #{col_name}, value => #{value}"
      @enc.write_bytes(key)
      @enc.write_bytes(col_name)
      @enc.write_bytes(value)
      @enc.write_long(timestamp)
      @enc.write_int(ttl)
    end

    #
    # Iterate through each key value pair in the hash to
    # be inserted and write directly one at a time
    #
    def put id, hsh, timestamp=nil, ttl=0
      timestamp ||= Time.now.to_i
      hsh.each do |attr, val|
        write_directly(id, attr, val, timestamp, ttl)
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

end
