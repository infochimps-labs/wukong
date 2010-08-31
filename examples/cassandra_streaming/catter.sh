#!/usr/bin/env bash

#
# Cat a binary-encoded avro file into the bulk loader
#

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
    -D cassandra.partitioner.class=org.apache.cassandra.dht.RandomPartitioner                    \
    -D cassandra.thrift.address="10.104.9.68"                                                    \
    -D cassandra.thrift.port=9160                                                                \
    -D mapred.reduce.tasks=0                                                                     \
    -libjars $ARCHIVES                                                                           \
    -file $avro_file                                                                             \
    -outputformat org.apache.cassandra.hadoop.ColumnFamilyOutputFormat                           \
    -mapper  	 `which cat`                                                                     \
    -input       "$input_file"                                                                   \
    -output  	 "$output_file"                                                                  \
    "$@"

