module Wukong
  module Store
    #
    # Barebones interface between a wukong class and a cassandra database
    #
    # Class must somehow provide a class-level cassandra_db accessor
    # that sets the @cassandra_db instance variable.
    #
    module CassandraModel
      #
      # Store model to the DB
      #
      def save
        self.class.insert key, self.to_db_hash
      end

      #
      # Store model using avro writer
      #
      def streaming_save
        self.class.streaming_insert key, self
      end
      #
      # Flatten attributes for storage in the DB.
      #
      # * omits elements whose value is nil
      # * calls to_s on everything else
      # * This means that blank strings are preserved;
      # * and that false is saved as 'false'
      #
      # Override if you think something fancier than that should happen.
      #
      def to_db_hash
        db_hsh = {}
        to_hash.each{|k,v| db_hsh[k.to_s] = v.to_s unless v.nil? }
        db_hsh
      end

      module ClassMethods
        # Cassandra column family -- taken from the class name by default.
        def table_name
          class_basename
        end

        # Override to control how your class is instantiated from the DB hash
        def from_db_hash *args
          from_hash *args
        end

        # Insert into the cassandra database
        # uses object's #to_db_hash method
        def insert key, *args
          hsh = args.first
          cassandra_db.insert(table_name, key.to_s, hsh)
        end

        def streaming_writer
          @streaming_writer ||= AvroWriter.new
        end

        #
        # Use avro and stream into cassandra
        #
        def streaming_insert key, hsh
          streaming_writer.put(key.to_s, hsh.to_db_hash)
        end

        # Insert into the cassandra database
        # calls out to object's #from_db_hash method
        def load key
          hsh = cassandra_db.get(self.class_basename, key.to_s)
          from_db_hash(hsh) if hsh
        end

        # invalidates cassandra connection on errors where that makes sense.
        def handle_error action, e
          warn "#{action} failed: #{e} #{e.backtrace.join("\t")}" ;
          @cassandra_db = nil
          sleep 0.2
        end
      end
      # The standard 'inject class methods when module is included' trick
      def self.included base
        base.class_eval{ extend ClassMethods}
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

      def write_directly key, col_name, value
        Log.info "Insert(row_key => #{key}, col_name => #{col_name}, value => #{value}"
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
      def put key, hsh
        hsh.each do |attr, val|
          write_directly(key, attr, val)
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
end

Hash.class_eval do
  #
  # Flatten attributes for storage in the DB.
  #
  # * omits elements whose value is nil
  # * calls to_s on everything else
  # * This means that blank strings are preserved;
  # * and that false is saved as 'false'
  #
  # Override if you think something fancier than that should happen.
  #
  def to_db_hash
    db_hsh = {}
    to_hash.each{|k,v| db_hsh[k.to_s] = v.to_s unless v.nil? }
    db_hsh
  end
end
