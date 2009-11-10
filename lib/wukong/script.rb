require 'pathname'
require 'wukong/script/hadoop_command'
require 'wukong/script/local_command'
require 'rbconfig'
module Wukong

  # == How to run a Wukong script
  #
  #   your/script.rb --run path/to/input_files path/to/output_dir
  #
  # All of the file paths are HDFS paths ; your script path, of course, is on the local filesystem.
  #
  # == Command-line options
  #
  # If you'd like to listen for any command-line options, specify them at the
  # command line:
  #
  #   your/script.rb --my_bool_opt --my_val_taking_opt=val \
  #     --run path/to/input_files path/to/output_dir
  #
  # In this case the options hash for both Mapper and Reducer will contain
  #
  #   :my_bool_opt       => true,
  #   :my_val_taking_opt => 'val'
  #
  # == Complicated input paths
  #
  # To use more than one file as input, you can use normal * ? [] wildcards or
  # give a comma-separated list -- see the hadoop documentation for syntax.
  #
  # == Run locally (--run=local)
  #
  # To run your script locally, use --run=local
  #
  #   your/script.rb --run=local path/to/input_files path/to/output_dir
  #
  # This will pipe the contents of path/to/input_files through first your
  # mapper, then sort, then the reducer, storing the results in the given output
  # directory.
  #
  # All paths refer to the /local/ filesystem -- hadoop is never involved and in
  # fact doesn't even have to be installed.
  #
  # == How to test your scripts
  #
  # You can supply the --map argument in place of --run to run the mapper on its
  # own (and similarly, --reduce to run the reducer standalone):
  #
  #   cat ./local/test/input.tsv | ./examples/word_count.rb --map | more
  #
  # or, if your test data lies on the HDFS,
  #
  #   hdp-cat test/input.tsv | ./examples/word_count.rb --map | more
  #
  #
  class Script
    include Wukong::HadoopCommand
    include Wukong::LocalCommand
    attr_accessor :mapper_klass, :reducer_klass, :options

    #
    # Instantiate the Script with the Mapper and the Reducer class (each a
    # Wukong::Streamer) it should call back.
    #
    #
    # == Identity or External program as map or reduce
    #
    # To use the identity reducer ('cat'), instantiate your Script class with
    # +nil+ as the reducer class. (And similarly to use an identity mapper,
    # supply +nil+ for the mapper class.)
    #
    # To use an external program as your reducer (mapper), subclass the
    # reduce_command (map_command) method to return the full command line
    # expression to call.
    #
    #   class MyMapper < Wukong::Streamer::Base
    #     # ... awesome stuff ...
    #   end
    #
    #   class MyScript < Wukong::Script
    #     # prefix each unique line with the count of its occurrences.
    #     def reduce_command
    #       '/usr/bin/uniq -c'
    #     end
    #   end
    #   MyScript.new(MyMapper, nil).run
    #
    def initialize mapper_klass, reducer_klass, extra_options={}
      self.options = default_options.merge(extra_options)
      process_argv!
      self.mapper_klass  = mapper_klass
      self.reducer_klass = reducer_klass
      # If no reducer_klass and no reduce_command, then skip the reduce phase
      options[:reduce_tasks] = 0 if (! reducer_klass) && (! options[:reduce_command]) && (! options[:reduce_tasks])
    end

    #
    # Gives default options.  Command line parameters take precedence
    #
    # MAKE SURE YOU CALL SUPER: write your script according to the patter
    #
    #   super.merge :my_option => :val
    #
    def default_options
      Wukong::CONFIG[:runner_defaults] || {}
    end

    # Options that don't need to go in the :all_args hash
    def std_options
      @std_options ||= [:run, :map, :reduce, ] + HADOOP_OPTIONS_MAP.keys
    end

    #
    # Parse the command-line args into the options hash.
    #
    # I should not reinvent the wheel.
    # Yet: here we are.
    #
    # '--foo=foo_val'  produces :foo => 'foo_val' in the options hash.
    # '--'             After seeing a non-'--' flag, or a '--' on its own, no further flags are parsed
    #
    # options[:all_args] contains all arguments that are not in std_options
    # options[:rest]     contains all arguments following the first non-flag (or the '--')
    #
    def process_argv!
      options[:all_args] = []
      options[:rest]     = []
      args      = ARGV.dup
      while (! args.blank?) do
        arg = args.shift
        case
        when arg == '--'
          options[:rest] += args
        when arg =~ /\A--(\w+)(?:=(.+))?\z/
          opt, val = [$1, $2]
          opt = opt.to_sym
          val ||= true
          self.options[opt] = val
          options[:all_args] << arg unless std_options.include?(opt)
        else
          options[:all_args]  << arg
          options[:rest]      << arg
        end
        # p [options, arg, args]
      end
      options[:all_args] = options[:all_args].join(" ")
    end

    def this_script_filename
      Pathname.new($0).realpath
    end

    def ruby_interpreter_path
      Pathname.new(
                   File.join(Config::CONFIG["bindir"],
                             Config::CONFIG["RUBY_INSTALL_NAME"]+
                             Config::CONFIG["EXEEXT"])
                   ).realpath
    end

    #
    # by default, call this script in --map mode
    #
    def map_command
      case
      when mapper_klass
        "#{ruby_interpreter_path} #{this_script_filename} --map " + options[:all_args]
      else options[:map_command] || Wukong::CONFIG[:default_mapper] end
    end

    #
    # Shell command for reduce phase
    # by default, call this script in --reduce mode
    #
    def reduce_command
      case
      when reducer_klass
        "#{ruby_interpreter_path} #{this_script_filename} --reduce " + options[:all_args]
      else options[:reduce_command] || Wukong::CONFIG[:default_reducer] end
    end

    #
    # Shell command to re-run in mapreduce mode using --map and --reduce
    #
    def runner_command input_path, output_path
      # run as either local or hadoop
      case run_mode
      when 'local'
        $stderr.puts "  Reading STDIN / Writing STDOUT"
        command = local_command input_path, output_path
      when 'hadoop', 'mapred'
        $stderr.puts "  Launching hadoop as"
        command = hadoop_command input_path, output_path
      else
        raise "Need to use --run=local or --run=hadoop; or to use the :default_run_mode in config.yaml just say --run "
      end
    end

    def run_mode
      # if only --run is given, assume default run mode
      options[:run] = Wukong::CONFIG[:default_run_mode] if (options[:run] == true)
      options[:run].to_s
    end

    def input_output_paths
      # input / output paths
      input_path, output_path = options[:rest][0..1]
      raise "You need to specify a parsed input directory and a directory for output. Got #{ARGV.inspect}" if (! options[:dry_run]) && (input_path.blank? || output_path.blank?)
      [input_path, output_path]
    end

    def maybe_overwrite_output_paths! output_path
      if (options[:overwrite] || options[:rm]) && (run_mode != 'local')
        $stderr.puts "Removing output file #{output_path}"
        `hdp-rm -r '#{output_path}'`
      end
    end

    #
    # Execute the runner phase
    #
    def exec_hadoop_streaming
      $stderr.puts "Streaming on self"
      input_path, output_path = input_output_paths
      maybe_overwrite_output_paths! output_path
      command = runner_command(input_path, output_path)
      $stderr.puts command
      unless options[:dry_run]
        $stdout.puts `#{command}`
      end
    end

    #
    # If --map or --reduce, dispatch to the mapper or reducer.
    # Otherwise,
    #
    def run
      case
      when options[:map]
        mapper_klass.new(self.options).stream
      when options[:reduce]
        reducer_klass.new(self.options).stream
      when options[:run]
        exec_hadoop_streaming
      else
        self.help # Normant Vincent Peale is proud of you
      end
    end

    #
    # Command line usage
    #
    def help
      $stderr.puts "#{self.class} script"
      $stderr.puts %Q{
        #{$0} --run=hadoop input_hdfs_path output_hdfs_dir    # run the script with hadoop streaming
        #{$0} --run=local  input_hdfs_path output_hdfs_dir    # run the script on local filesystem using unix pipes
        #{$0} --run        input_hdfs_path output_hdfs_dir    # run the script with the mode given in config/wukong*.yaml
        #{$0} --map
        #{$0} --reduce                                        # dispatch to the mapper or reducer

      All flags must precede the input and output paths.
      Additional flags:
        --dry_run
      Hadoop Options (see hadoop documentation)
        --max_node_map_tasks     => 'mapred.tasktracker.map.tasks.maximum',
        --max_node_reduce_tasks  => 'mapred.tasktracker.reduce.tasks.maximum',
        --map_tasks              => 'mapred.map.tasks',
        --reduce_tasks           => 'mapred.reduce.tasks',
        --sort_fields            => 'stream.num.map.output.key.fields',
        --key_field_separator    => 'map.output.key.field.separator',
        --partition_fields       => 'num.key.fields.for.partition',
        --output_field_separator => 'stream.map.output.field.separator',
        --map_speculative        => 'mapred.map.tasks.speculative.execution',
        --timeout                => 'mapred.task.timeout',
        --reuse_jvms             => 'mapred.job.reuse.jvm.num.tasks',
        --ignore_exit_status     => 'stream.non.zero.exit.status.is.failure',
      You can specify as well arbitrary script-specific command line flags; they are added to your options[] hash.
      }
    end
  end

end
