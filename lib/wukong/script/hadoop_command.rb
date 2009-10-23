# -*- coding: utf-8 -*-
module Wukong
  module HadoopCommand

    # ===========================================================================
    #
    # Hadoop Environment
    #

    module ClassMethods
      #
      # Via @pskomoroch via @tlipcon,
      #
      #  "there is a little known Hadoop Streaming trick buried in this Python
      #   script. You will notice that the date is not actually in the raw log
      #   data itself, but is part of the filename. It turns out that Hadoop makes
      #   job parameters you would fetch in Java with something like
      #   job.get("mapred.input.file") available as environment variables for
      #   streaming jobs, with periods replaced with underscores:
      #
      #     filepath = os.environ["map_input_file"]
      #     filename = os.path.split(filepath)[-1]
      #   Thanks to Todd Lipcon for directing me to that hack.
      #

      # "HADOOP_HOME"                             =>"/usr/lib/hadoop-0.20/bin/..",
      # "HADOOP_IDENT_STRING"                     =>"hadoop",
      # "HADOOP_LOGFILE"                          =>"hadoop-hadoop-tasktracker-ip-10-242-14-223.log",
      # "HADOOP_LOG_DIR"                          =>"/usr/lib/hadoop-0.20/bin/../logs",
      # "HOME"                                    =>"/var/run/hadoop-0.20",
      # "JAVA_HOME"                               =>"/usr/lib/jvm/java-6-sun",
      # "LD_LIBRARY_PATH"                         =>"/usr/lib/jvm/java-6-sun-1.6.0.10/jre/lib/i386/client:/usr/lib/jvm/java-6-sun-1.6.0.10/jre/lib/i386:/usr/lib/jvm/java-6-sun-1.6.0.10/jre/../lib/i386:/mnt/hadoop/mapred/local/taskTracker/jobcache/job_200910221152_0023/attempt_200910221152_0023_m_000000_0/work:/usr/lib/jvm/java-6-sun-1.6.0.10/jre/lib/i386/client:/usr/lib/jvm/java-6-sun-1.6.0.10/jre/lib/i386:/usr/lib/jvm/java-6-sun-1.6.0.10/jre/../lib/i386",
      # "PATH"                                    =>"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games",
      # "USER"                                    =>"hadoop",
      #
      # "dfs_block_size"                          =>"134217728",
      # "map_input_start"                         =>"0",
      # "map_input_length"                        =>"125726898",
      # "mapred_output_key_class"                 =>"org.apache.hadoop.io.Text",
      # "mapred_output_value_class"               =>"org.apache.hadoop.io.Text",
      # "mapred_output_format_class"              =>"org.apache.hadoop.mapred.TextOutputFormat",
      # "mapred_output_compression_codec"         =>"org.apache.hadoop.io.compress.DefaultCodec",
      # "mapred_output_compression_type"          =>"BLOCK",
      # "mapred_task_partition"                   =>"0",
      # "mapred_tasktracker_map_tasks_maximum"    =>"4",
      # "mapred_tasktracker_reduce_tasks_maximum" =>"2",
      # "mapred_tip_id"                           =>"task_200910221152_0023_m_000000",
      # "mapred_task_id"                          =>"attempt_200910221152_0023_m_000000_0",
      # "mapred_job_tracker"                      =>"ec2-174-129-141-78.compute-1.amazonaws.com:8021",
      #
      # "mapred_input_dir"                        =>"hdfs://ec2-174-129-141-78.compute-1.amazonaws.com/user/flip/ripd/com.tw/com.twitter.search/20090809",
      # "map_input_file"                          =>"hdfs://ec2-174-129-141-78.compute-1.amazonaws.com/user/flip/ripd/com.tw/com.twitter.search/20090809/com.twitter.search+20090809233441-56735-womper.tsv.bz2",
      # "mapred_working_dir"                      =>"hdfs://ec2-174-129-141-78.compute-1.amazonaws.com/user/flip",
      # "mapred_work_output_dir"                  =>"hdfs://ec2-174-129-141-78.compute-1.amazonaws.com/user/flip/tmp/twsearch-20090809/_temporary/_attempt_200910221152_0023_m_000000_0",
      # "mapred_output_dir"                       =>"hdfs://ec2-174-129-141-78.compute-1.amazonaws.com/user/flip/tmp/twsearch-20090809",
      # "mapred_temp_dir"                         =>"/mnt/tmp/hadoop-hadoop/mapred/temp",
      # "PWD"                                     =>"/mnt/hadoop/mapred/local/taskTracker/jobcache/job_200910221152_0023/attempt_200910221152_0023_m_000000_0/work",
      # "TMPDIR"                                  =>"/mnt/hadoop/mapred/local/taskTracker/jobcache/job_200910221152_0023/attempt_200910221152_0023_m_000000_0/work/tmp",
      # "stream_map_streamprocessor"              =>"%2Fusr%2Fbin%2Fruby1.8+%2Fmnt%2Fhome%2Fflip%2Fics%2Fwuclan%2Fexamples%2Ftwitter%2Fparse%2Fparse_twitter_search_requests.rb+--map+--rm",
      # "user_name"                               =>"flip",

      def input_file
        ENV['mapred_input_file']
      end

      def attempt_id
        ENV['mapred_task_id']
      end
      def curr_task_id
        ENV['mapred_tip_id']
      end

      def script_cmdline_urlenc
        ENV['stream_map_streamprocessor']
      end
    end
    # Standard ClassMethods-on-include trick
    def self.included base
      base.class_eval do
        extend ClassMethods
      end
    end

    # ===========================================================================
    #
    # Hadoop Options
    #

    #
    # Translate the simplified args to their hairy-assed hadoop equivalents
    #
    HADOOP_OPTIONS_MAP = {
      :max_node_map_tasks     => 'mapred.tasktracker.map.tasks.maximum',
      :max_node_reduce_tasks  => 'mapred.tasktracker.reduce.tasks.maximum',
      :map_tasks              => 'mapred.map.tasks',
      :reduce_tasks           => 'mapred.reduce.tasks',
      :sort_fields            => 'stream.num.map.output.key.fields',
      :key_field_separator    => 'map.output.key.field.separator',
      :partition_fields       => 'num.key.fields.for.partition',
      :output_field_separator => 'stream.map.output.field.separator',
      :map_speculative        => 'mapred.map.tasks.speculative.execution',
      :timeout                => 'mapred.task.timeout',
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

    # Emit options for setting the number of mappers and reducers.
    def hadoop_num_tasks_args
      [
        jobconf(:max_node_map_tasks),
        jobconf(:max_node_reduce_tasks),
        jobconf(:map_tasks),
        jobconf(:reduce_tasks)
      ]
    end

    def hadoop_other_args
      extra_str_args = [ options[:extra_args] ]
      extra_hsh_args = [:map_speculative, :timeout].map{|opt| jobconf(opt)  }
      extra_str_args + extra_hsh_args
    end

    #
    # Assemble the hadoop command to execute
    #
    def hadoop_command input_path, output_path
      # If this is wrong, create a config/wukong-site.rb or
      # otherwise set Wukong::CONFIG[:hadoop_home] to the
      # root of your config install.
      hadoop_program = Wukong::CONFIG[:hadoop_home]+'/bin/hadoop'
      [
        hadoop_program,
        "jar #{Wukong::CONFIG[:hadoop_home]}/contrib/streaming/hadoop-*-streaming.jar",
        hadoop_partition_args,
        hadoop_sort_args,
        hadoop_num_tasks_args,
        "-mapper  '#{map_command}'",
        "-reducer '#{reduce_command}'",
        "-input   '#{input_path}'",
        "-output  '#{output_path}'",
        hadoop_other_args,
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
