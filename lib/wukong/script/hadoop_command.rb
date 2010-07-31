# -*- coding: utf-8 -*-
module Wukong
  module HadoopCommand

    # ===========================================================================
    #
    # Hadoop Environment
    #

    # ===========================================================================
    #
    # Hadoop Options
    #

    #
    # Translate the simplified args to their hairy-assed hadoop equivalents
    #
    Settings.define :max_node_map_tasks,     :jobconf => true, :description => 'mapred.tasktracker.map.tasks.maximum', :wukong => true
    Settings.define :max_node_reduce_tasks,  :jobconf => true, :description => 'mapred.tasktracker.reduce.tasks.maximum', :wukong => true
    Settings.define :map_tasks,              :jobconf => true, :description => 'mapred.map.tasks', :wukong => true
    Settings.define :reduce_tasks,           :jobconf => true, :description => 'mapred.reduce.tasks', :wukong => true
    Settings.define :sort_fields,            :jobconf => true, :description => 'stream.num.map.output.key.fields', :wukong => true
    Settings.define :key_field_separator,    :jobconf => true, :description => 'map.output.key.field.separator', :wukong => true
    Settings.define :partition_fields,       :jobconf => true, :description => 'num.key.fields.for.partition', :wukong => true
    Settings.define :output_field_separator, :jobconf => true, :description => 'stream.map.output.field.separator', :wukong => true
    Settings.define :map_speculative,        :jobconf => true, :description => 'mapred.map.tasks.speculative.execution', :wukong => true
    Settings.define :timeout,                :jobconf => true, :description => 'mapred.task.timeout', :wukong => true
    Settings.define :reuse_jvms,             :jobconf => true, :description => 'mapred.job.reuse.jvm.num.tasks', :wukong => true
    Settings.define :respect_exit_status,    :jobconf => true, :description => 'stream.non.zero.exit.is.failure', :wukong => true
    Settings.define :io_sort_record_percent, :jobconf => true, :description => 'io.sort.record.percent', :wukong => true
    Settings.define :io_sort_mb,             :jobconf => true, :description => 'io.sort.mb', :wukong => true
    Settings.define :noempty,                                  :description => "don't create zero-byte reduce files (hadoop mode only)", :wukong => true
    Settings.define :job_name,               :jobconf => true, :description => 'mapred.job.name', :wukong => true
    # mapred.linerecordreader.maxlength :description => "Safeguards against corrupted data: lines longer than this (in bytes) are treated as bad records."
    Settings.define :max_reduces_per_node,   :jobconf => true, :description => 'mapred.max.reduces.per.node',    :wukong => true
    Settings.define :max_reduces_per_cluster,:jobconf => true, :description => 'mapred.max.reduces.per.cluster', :wukong => true
    Settings.define :max_maps_per_node,      :jobconf => true, :description => 'mapred.max.maps.per.node',       :wukong => true
    Settings.define :max_maps_per_cluster,   :jobconf => true, :description => 'mapred.max.maps.per.cluster',    :wukong => true

    # emit a -jobconf hadoop option if the simplified command line arg is present
    # if not, the resulting nil will be elided later
    def jobconf option
      if options[option]
        "-jobconf %s=%s" % [options.description_for(option), options[option]]
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
      unless options[:partition_fields].blank?
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

    def hadoop_other_args input_path, output_path
      extra_str_args  = [ options[:extra_args] ]
      extra_str_args               += ' -lazyOutput' if options[:noempty]  # don't create reduce file if no records
      options[:reuse_jvms]          = '-1'     if (options[:reuse_jvms] == true)
      options[:respect_exit_status] = 'false'  if (options[:ignore_exit_status] == true)
      options[:job_name] ||= "#{File.basename(this_script_filename)}---#{input_path}---#{output_path}".gsub(%r{[^\w/\.\-\+]+}, '')
      extra_hsh_args = [:job_name, :map_speculative, :timeout, :reuse_jvms, :respect_exit_status].map{|opt| jobconf(opt)  }
      extra_str_args + extra_hsh_args
    end

    def hadoop_recycle_env
      %w[RUBYLIB].map do |var|
        %Q{-cmdenv '#{var}=#{ENV[var]}'} if ENV[var]
      end.compact
    end

    # The path to the hadoop runner script
    def hadoop_runner
      options[:hadoop_runner] || (options[:hadoop_home]+'/bin/hadoop')
    end

    #
    # Assemble the hadoop command to execute
    #
    def hadoop_command input_path, output_path
      # If this is wrong, create a config/wukong-site.rb or
      # otherwise set Settings[:hadoop_home] to the
      # root of your config install.
      [
        hadoop_runner,
        "jar #{Settings[:hadoop_home]}/contrib/streaming/hadoop-*streaming*.jar",
        hadoop_partition_args,
        hadoop_sort_args,
        hadoop_num_tasks_args,
        "-mapper  '#{map_command}'",
        "-reducer '#{reduce_command}'",
        "-input   '#{input_path}'",
        "-output  '#{output_path}'",
        hadoop_recycle_env,
        hadoop_other_args(input_path, output_path),
      ].flatten.compact.join(" \t\\\n  ")
    end


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

      # HDFS pathname to the input file currently being processed.
      def input_file
        ENV['map_input_file']
      end

      # Directory of the input file
      def input_dir
        ENV['mapred_input_dir']
      end

      # Offset of this chunk within the input file
      def map_input_start_offset
        ENV['map_input_start']
      end

      # length of the mapper's input chunk
      def map_input_length
        ENV['map_input_length']
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
