module Wukong
  class RunnerResult
    field :runner,      Runner, :doc => 'Runner object that created this job'
    field :command,     Array, :of => String, :doc => 'launch command'
    field :beg_time,    Time
    field :end_time,    Time
    field :raw_out,     String
    field :raw_err,     String
  end

  #
  # A uniform interface for launching processes.
  #
  # * accepts humanized and standardized args
  # * synthesize args into a command
  # * launch the process
  # * parse its output
  #
  class Runner
    class_attribute :result_parser ; self.result_parser = RunnerResult

    field :name, Symbol, :required => true
    field :executor_path, Pathname, :required => true

    def to_long_params(arg_hsh, dash='-')
      arg_hsh.inject([]) do |acc, (param, val)|
        param = param.to_s.gsub(/[\-_\W]+/, dash)
        acc << "--#{param.to_s}" << val.to_s
      end
    end

    def native_args(arg_hsh)
      to_dashed_params(arg_hsh)
    end

    def command(arg_hsh)
      [executor_path, *native_args(arg_hsh)]
    end

    def run(input, arg_hsh)
      cmd        = command(input, arg_hsh)
      beg_time   = Time.now
      out, err   = launch( *cmd )
      end_time   = Time.now

      result_parser.new({
          :runner     => self,
          :command    => cmd,
          :beg_time   => beg_time,
          :end_time   => end_time,
          :input      => input,
          :arg_hsh    => arg_hsh,
          :raw_out    => out,
          :raw_err    => err,
        })
    end

    class << self
      def executor(*args)
        ArgumentError.check_arity!(args, 1)
        @executor = args.first if args.present?
        @executor
      end

      def launch(*cmd)
        out = `#{cmd.join(' ')}`
      end

      def which(basename)
        raise ArgumentError, "which wants a basename, not a path (#{basename})" if basename =~ %r{\/}
        out, err = launch('which', basename)
        out.chomp
      end

    end
  end

  module RunnerWithInputOutput
    extend Gorillib::Concern
    included do
      has_inputs
      has_outputs
    end

    # sugar for a command that takes input to produce output.
    #
    # @param [Array<String>, String] inputs -- added as the `:inputs` arg (converting to an array if necessary)
    # @param [String] output -- added as the `:output` arg
    #
    def run(inputs, output, args={})
      inputs = Array.wrap(inputs)
      super args.merge(:inputs => inputs, :output => output)
    end
  end

  #
  # Wukong::Runner interface for the `cp` command
  #
  # @example
  #   runner = Wukong::CpRunner.new
  #   runner.run('my_src.jpg', 'my_dest.jpg')
  #
  class CpRunner
    include  RunnerWithInputOutput
    executor which('cp')

    argument :verbose,      Boolean, :native => '-v', :solo => true, :doc => 'show files as they are copied'
    argument :duplicate,    Boolean, :native => '-a', :solo => true, :doc => 'Preserves structure and attributes of files'
  end

  class ScpRunner
    include  RunnerWithInputOutput
    executor which('scp')

    argument :verbose,      Boolean,  :native => '-v', :solo => true, :doc => 'show files as they are copied'
    argument :duplicate,    Boolean,  :native => '-p', :solo => true, :doc => 'Preserves structure and attributes of files'
    #
    argument :ssh_user,     String
    argument :dest_host,    String
    argument :ssh_key_file, Pathname, :native => '-i'
    argument :dest_port,    Integer,  :native => '-P'

    argument :compression,  Boolean,  :native => '-C'
    argument :recursive,    Boolean,  :native => '-r'

    self.success_exit_status = 0
  end

  module RunnerForJava

    argument :java_home, :env_var => 'JAVA_HOME', :doc => 'path to the java environment; $JAVA_HOME/bin usually holds your java runner'

    argument :java_prog, :finally => ->(){ path_to(arg_val(:java_home), 'bin', 'java') }

    argument :jar

    argument :classpath

    def java_conf
    end

  end

  class HadoopRunner
    include  RunnerWithInputOutput
    executor which('hadoop')

    argument :verbose,      Boolean,  :native => '-v', :solo => true, :doc => 'show files as they are copied'

    argument :hadoop_home, :default => '/usr/lib/hadoop', :doc => "Path to hadoop installation; ENV['HADOOP_HOME'] by default. HADOOP_HOME/bin/hadoop is used to run hadoop.", :env_var => 'HADOOP_HOME'
    argument :hadoop_runner,                            :doc => "Path to hadoop script. Usually set --hadoop_home instead of this."

    #
    # Translate simplified args to their hairy hadoop equivalents
    #
    argument :job_name,               :jobconf => 'mapred.job.name'
    #
    argument :io_sort_mb,             :jobconf => 'io.sort.mb'
    argument :io_sort_record_percent, :jobconf => 'io.sort.record.percent'
    argument :key_field_separator,    :jobconf => 'map.output.key.field.separator'
    argument :map_speculative,        :jobconf => 'mapred.map.tasks.speculative.execution'
    argument :map_tasks,              :jobconf => 'mapred.map.tasks'
    argument :max_maps_per_cluster,   :jobconf => 'mapred.max.maps.per.cluster'
    argument :max_maps_per_node,      :jobconf => 'mapred.max.maps.per.node'
    argument :max_node_map_tasks,     :jobconf => 'mapred.tasktracker.map.tasks.maximum'
    argument :max_node_reduce_tasks,  :jobconf => 'mapred.tasktracker.reduce.tasks.maximum'
    argument :max_record_length,      :jobconf => 'mapred.linerecordreader.maxlength', :doc => "Safeguards against corrupted data: lines longer than this (in bytes) are treated as bad records."
    argument :max_reduces_per_cluster,:jobconf => 'mapred.max.reduces.per.cluster'
    argument :max_reduces_per_node,   :jobconf => 'mapred.max.reduces.per.node'
    argument :max_tracker_failures,   :jobconf => 'mapred.max.tracker.failures'
    argument :max_map_attempts,       :jobconf => 'mapred.map.max.attempts'
    argument :max_reduce_attempts,    :jobconf => 'mapred.reduce.max.attempts'
    argument :min_split_size,         :jobconf => 'mapred.min.split.size'
    argument :output_field_separator, :jobconf => 'stream.map.output.field.separator'
    argument :partition_fields,       :jobconf => 'num.key.fields.for.partition'
    argument :reduce_tasks,           :jobconf => 'mapred.reduce.tasks'
    argument :respect_exit_status,    :jobconf => 'stream.non.zero.exit.is.failure'
    argument :reuse_jvms,             :jobconf => 'mapred.job.reuse.jvm.num.tasks'
    argument :sort_fields,            :jobconf => 'stream.num.map.output.key.fields'
    argument :timeout,                :jobconf => 'mapred.task.timeout'
    argument :noempty,                                  :doc => "don't create zero-byte reduce files (hadoop mode only)"
    argument :split_on_xml_tag,                         :doc => "Parse XML document by specifying the tag name: 'anything found between <tag> and </tag> will be treated as one record for map tasks'"


    argument :mapper_command,  String, :native => '-mapper'
    argument :reducer_command, String, :native => '-reducer'

    repeated_argument :file, String, :native => '-file'

    # emit a -jobconf hadoop option if the simplified command line arg is present
    def jobconf option
      if settings[option]
        # "-jobconf %s=%s" % [settings.definition_of(option, :description), settings[option]]
        "-D %s=%s" % [settings.definition_of(option, :description), settings[option]]
      end
    end

    def finalize_settings
      settings[:reuse_jvms] = '-1'             if (settings[:reuse_jvms] == true)
      settings[:respect_exit_status] = 'false' if (settings[:ignore_exit_status] == true)
      settings[:reduce_tasks] = 0 if (! settings[:reduce_command])
    end

    def hadoop_other_args
      extra_str_args  = [ settings[:extra_args] ]
      if settings.split_on_xml_tag
        extra_str_args << %Q{-inputreader 'StreamXmlRecordReader,begin=<#{settings.split_on_xml_tag}>,end=</#{settings.split_on_xml_tag}>'}
      end
      extra_str_args   << ' -lazyOutput' if settings[:noempty]  # don't create reduce file if no records
      extra_str_args   << ' -partitioner org.apache.hadoop.mapred.lib.KeyFieldBasedPartitioner' unless settings[:partition_fields].blank?
      extra_str_args
    end

    def hadoop_recycle_env
      %w[RUBYLIB].map do |var|
        %Q{-cmdenv '#{var}=#{ENV[var]}'} if ENV[var]
      end.compact
    end

    # The path to the hadoop runner script
    def hadoop_runner
      settings[:hadoop_runner] || (settings[:hadoop_home]+'/bin/hadoop')
    end

    #
    # Assemble the hadoop command to execute
    # and launch the hadoop runner to execute the script across all tasktrackers
    #
    # FIXME: Should add some simple logic to ensure that commands are in the
    # right order or hadoop will complain. ie. -D settings MUST come before
    # others
    #
    def execute_hadoop_workflow
      # Input paths join by ','
      input_paths = @input_paths.join(',')
      #
      # Use Settings[:hadoop_home] to set the path your config install.
      hadoop_commandline = [
        hadoop_runner,
        "jar #{settings[:hadoop_home]}/contrib/streaming/hadoop-*streaming*.jar",
        hadoop_jobconf_settings,
        "-D mapred.job.name='#{job_name}'",
        hadoop_other_args,
        "-mapper  '#{mapper_commandline}'",
        "-reducer '#{reducer_commandline}'",
        "-input   '#{input_paths}'",
        "-output  '#{output_path}'",
        "-file    '#{this_script_filename}'",
        hadoop_recycle_env,
      ].flatten.compact.join(" \t\\\n  ")
      Log.info "  Launching hadoop!"
      execute_command!(hadoop_commandline)
    end

  end


  #
  # Req
  #
  class HadoopJob
    field :job_id
    field :k

    def from_jobtracker(jobtracker_host)
      contents = fetch_jobtracker_raw(jobtracker_host)
      attrs = parse_jobtracker_raw(contents)
    end

    def fetch_jobtracker_raw(jobtracker_host)
    end

    def parse_jobtracker_raw(contents)
    end
  end


end
