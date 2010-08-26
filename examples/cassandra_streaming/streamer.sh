#!/usr/bin/env bash

input_file="$1" 		 ; shift
output_file="$1" 		 ; shift
map_script=${1-/bin/cat}	 ; shift
reduce_script=${1-/usr/bin/uniq} ; shift

dest_keyspace=${dest_keyspace-soc_net_tw}
dest_col_family=${dest_col_family-Wordbag}

hostname=`hostname`

# Path to cassandra and hadoop dirs
CASSANDRA_HOME=${CASSANDRA_HOME-/usr/local/share/cassandra}
HADOOP_HOME=${HADOOP_HOME-/usr/lib/hadoop}


ARCHIVES=`/bin/ls -1 $CASSANDRA_HOME/build/apache-cassandra*.jar`
for jar in `/bin/ls -1 $CASSANDRA_HOME/build/lib/jars/*.jar $CASSANDRA_HOME/lib/*.jar`; do
    ARCHIVES=$ARCHIVES,$jar
done

${HADOOP_HOME}/bin/hadoop                                                                        \
     jar         ${HADOOP_HOME}/contrib/streaming/hadoop-*streaming*.jar                         \
    -D stream.map.output=cassandra_avro_output                                                   \
    -D stream.io.identifier.resolver.class=org.apache.cassandra.hadoop.streaming.AvroResolver    \
    -D cassandra.output.keyspace="$dest_keyspace"                                                \
    -D cassandra.output.columnfamily="$dest_col_family"                                          \
    -D cassandra.partitioner.class=org.apache.cassandra.dht.RandomPartitioner                    \
    -D cassandra.thrift.address="$hostname"                                                      \
    -D cassandra.thrift.port=9160                                                                \
    -D mapred.reduce.tasks=0                                                                     \
    -libjars $ARCHIVES                                                                           \
    -file cassandra.avpr                                                                         \
    -outputformat org.apache.cassandra.hadoop.ColumnFamilyOutputFormat                           \
    -mapper  	 "ruby /home/jacob/Programming/cassandra_streaming_example/avromapper.rb --map " \
    -input       "$input_file"                                                                   \
    -output  	 "$output_file"                                                                  \
    "$@"
    
# echo $cmd
# $cmd
