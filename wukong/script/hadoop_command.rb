# -*- coding: utf-8 -*-
module Wukong
  module HadoopCommand

    # ===========================================================================
    #
    # Hadoop Options
    #

    #
    # Translate the simplified args to their hairy-assed hadoop equivalents
    #
    HADOOP_OPTIONS_MAP = {
      :max_map_tasks          => 'mapred.tasktracker.map.tasks.maximum',
      :map_tasks              => 'mapred.map.tasks',
      :reduce_tasks           => 'mapred.reduce.tasks',
      :sort_fields            => 'stream.num.map.output.key.fields',
      :key_field_separator    => 'map.output.key.field.separator',
      :partition_fields         => 'num.key.fields.for.partition',
      :output_field_separator => 'stream.map.output.field.separator'
    }

    # emit a -jobconf hadoop option if the simplified command line arg is present
    # if not, the resulting nil will be elided later
    def jobconf option
      if options[option]
        "-jobconf %s=%s" % [HADOOP_OPTIONS_MAP[option], options[option]]
      end
    end

    # Define what fields hadoop should treat as the keys
    def hadoop_sort_args
      [
        jobconf(:key_field_separator),
        jobconf(:sort_fields),
      ]
    end

    # Define what fields hadoop should use to distribute records to reducers
    def hadoop_partition_args
      if options[:partition_fields]
        [
          '-partitioner org.apache.hadoop.mapred.lib.KeyFieldBasedPartitioner',
          jobconf(:output_field_separator),
          jobconf(:partition_fields),
        ]
      end
    end

    # Emit options for setting the number of mappers and reducers.  The
    # asymmetry of :max_map_tasks and :reduce_tasks is purposeful --
    # mapred.map.tasks doesn't really do what you think it does.
    def hadoop_num_tasks_args
      [
        jobconf(:max_map_tasks),
        jobconf(:map_tasks),
        jobconf(:reduce_tasks)
      ]
    end

    #
    # Assemble the hadoop command to execute
    #
    def hadoop_command input_path, output_path
      hadoop_program = CONFIG[:hadoop_home]+'/bin/hadoop'
      [
        hadoop_program,
        "jar #{CONFIG[:hadoop_home]}/contrib/streaming/hadoop-*-streaming.jar",
        hadoop_partition_args,
        hadoop_sort_args,
        hadoop_num_tasks_args,
        "-mapper  '#{map_command}'",
        "-reducer '#{reduce_command}'",
        "-input   '#{input_path}'",
        "-output  '#{output_path}'"
      ].flatten.compact.join(" \t\\\n  ")
    end

  end
end


# -inputformat     <name of inputformat (class)> (“auto” by default)
# -input           <additional DFS input path>
# -python          <python command to use on nodes> (“python” by default)
# -name            <job name> (“program.py” by default)
# -numMapTasks     <number>
# -numReduceTasks  <number> (no sorting or reducing will take place if this is 0)
# -priority        <priority value> (“NORMAL” by default)
# -libjar          <path to jar> (this jar gets put in the class path)
# -libegg          <path to egg> (this egg gets put in the Python path)
# -file            <local file> (this file will be put in the dir where the python program gets executed)
# -cacheFile       hdfs://<host>:<fs_port>/<path to file>#<link name> (a link ”<link name>” to the given file will be in the dir)
# -cacheArchive    hdfs://<host>:<fs_port>/<path to jar>#<link name> (link points to dir that contains files from given jar)
# -cmdenv          <env var name>=<value>
# -jobconf         <property name>=<value>
# -addpath         yes (replace each input key by a tuple consisting of the path of the corresponding input file and the original key)
# -fake            yes (fake run, only prints the underlying shell commands but does not actually execute them)
# -memlimit        <number of bytes> (set an upper limit on the amount of memory that can be used)
