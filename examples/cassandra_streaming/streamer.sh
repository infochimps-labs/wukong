#!/usr/bin/env bash

input_file="$1" 		 ; shift
output_file="$1" 		 ; shift
map_script=${1-/bin/cat}	 ; shift
reduce_script=${1-/usr/bin/uniq} ; shift

dest_keyspace=${dest_keyspace-soc_net_tw}
dest_col_family=${dest_col_family-Wordbag}

hostname=`hostname`

# Path to cassandra and hadoop dirs
script_dir=$(readlink -f `dirname $0`)
CASSANDRA_HOME=${CASSANDRA_HOME-/usr/local/share/cassandra}
HADOOP_HOME=${HADOOP_HOME-/usr/lib/hadoop}
avro_file=${avro_file-$CASSANDRA_HOME/interface/avro/cassandra.avpr}

ARCHIVES=`/bin/ls -1 $CASSANDRA_HOME/build/apache-cassandra*.jar`
for jar in `/bin/ls -1 $CASSANDRA_HOME/build/lib/jars/*.jar $CASSANDRA_HOME/lib/*.jar`; do
    ARCHIVES=$ARCHIVES,$jar
done

${HADOOP_HOME}/bin/hadoop                                                                        \
     jar ${HADOOP_HOME}/contrib/streaming/hadoop-*streaming*.jar                                 \
    -D stream.map.output=cassandra_avro_output                                                   \
    -D stream.io.identifier.resolver.class=org.apache.cassandra.hadoop.streaming.AvroResolver    \
    -D cassandra.output.keyspace="$dest_keyspace"                                                \
    -D cassandra.output.columnfamily="$dest_col_family"                                          \
    -D cassandra.thrift.address=10.204.41.193,10.204.30.11,10.204.58.238,10.204.239.133,10.196.191.31,10.204.103.21,10.202.74.223,10.202.143.95 \
    -D cassandra.partitioner.class=org.apache.cassandra.dht.RandomPartitioner                    \
    -D cassandra.thrift.port=9160                                                                \
    -D mapreduce.output.columnfamilyoutputformat.batch.threshold=1024                            \
    -D mapred.reduce.tasks=0                                                                     \
    -D mapred.map.tasks.speculative.execution=false                                              \
    -libjars $ARCHIVES                                                                           \
    -file $avro_file                                                                             \
    -outputformat org.apache.cassandra.hadoop.ColumnFamilyOutputFormat                           \
    -mapper  	 "ruby $script_dir/avromapper.rb --map "                                         \
    -input       "$input_file"                                                                   \
    -output  	 "$output_file"                                                                  \
    "$@"

    # -D cassandra.thrift.address=10.204.54.190,10.244.42.31,10.244.42.176,10.244.42.112,10.244.42.143,10.244.42.79,10.244.42.4,10.204.53.166 \
    # -D cassandra.thrift.address=10.204.221.230,10.243.79.223,10.245.19.159,10.242.154.159,10.242.153.155,10.242.153.203 \


# cat /tmp/mj-flip/chimchim-info.log | cut -f5 | ruby -e 'puts $stdin.readlines.map{|l| l.chomp.gsub(/ip-([0-9\-]+)\..*/,"\\1").gsub(/-/,".") }.join(",")'



