Settings.define :cass_keyspace,   :default => 'soc_net_tw'
Settings.define :cass_col_family, :default => 'TwitterUser'
Settings.define :cassandra_home,  :env_var => 'CASSANDRA_HOME', :default => '/usr/local/share/cassandra'

module Wukong
  class CassandraScript < Wukong::Script
    def hadoop_other_args *args
      opts = super(*args)
      opts << "-D stream.map.output=\'cassandra_avro_output\'"
      opts << "-D stream.io.identifier.resolver.class=\'org.apache.cassandra.hadoop.streaming.AvroResolver\'"
      opts << "-D cassandra.output.keyspace=\'#{Settings.dest_keyspace}\'"
      opts << "-D cassandra.output.columnfamily=\'#{Settings.dest_col_family}\'"
      opts << "-D cassandra.partitioner.class=\'org.apache.cassandra.dht.RandomPartitioner\'"
      opts << "-D cassandra.thrift.address=\'10.204.41.193\'"
      opts << "-D cassandra.thrift.port=\'9160\'"
      opts << "-D mapreduce.output.columnfamilyoutputformat.batch.threshold=\'1024\'"
      # ORDER MATTERS
      opts << "-libjars \'#{cassandra_jars}\'"
      opts << "-file    \'#{Settings.cassandra_avro_schema}\'"
      opts << "-outputformat \'org.apache.cassandra.hadoop.ColumnFamilyOutputFormat\'"
      opts
    end

    #
    # Return paths to cassandra jars as a string
    #
    def cassandra_jars
      jars = []
      Dir["#{Settings.cassandra_home}/build/apache-cassandra*.jar", "#{Settings.cassandra_home}/build/lib/jars/*.jar", "#{Settings.cassandra_home}/lib/*.jar"].each do |jar|
        jars << jar
      end
      jars.join(',')
    end

    def avro_schema
      File.join(Settings.cassandra_home, "interface/avro/cassandra.avpr")
    end

  end
end
