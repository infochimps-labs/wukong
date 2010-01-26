require 'pathname'
require 'wukong/script/hadoop_command'
require 'wukong/script/local_command'
require 'configliere' ; Configliere.use(:commandline, :env_var, :define)
require 'rbconfig' # for uncovering ruby_interpreter_path
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

    # ---------------------------------------------------------------------------
    #
    # Default options for Wukong
    #   http://github.com/infochimps/wukong
    #
    # If you set an environment variable WUKONG_CONFIG, *or* if the file
    # $HOME/.wukong.rb exists, that file will be +require+'d as well.
    #
    # Important values to set:
    #
    # * hadoop_home -- Path to root of hadoop install. If your hadoop runner is
    #     /usr/local/share/hadoop/bin/hadoop
    #   then your hadoop_home is
    #     /usr/local/share/hadoop.
    #   You can also set a :hadoop_runner that gives the full path to the hadoop script
    #
    # * default_run_mode -- Whether to run using hadoop (and
    #   thus, requiring a working hadoop install), or to run in local mode
    #   (script --map | sort | script --reduce)
    #
    Settings.define :default_run_mode, :default => 'hadoop',    :description => 'Run as local or as hadoop?', :wukong => true, :hide_help => false
    Settings.define :default_mapper,   :default => '/bin/cat',  :description => 'The command to run when a nil mapper is given.', :wukong => true, :hide_help => true
    Settings.define :default_reducer,  :default => '/bin/cat',  :description => 'The command to run when a nil reducer is given.', :wukong => true, :hide_help => true
    Settings.define :hadoop_home,      :default => '/usr/lib/hadoop', :environment => 'HADOOP_HOME', :description => "Path to hadoop installation; :hadoop_home/bin/hadoop should run hadoop.", :wukong => true
    Settings.define :hadoop_runner,    :description => "Path to hadoop script; usually, set :hadoop_home instead of this.", :wukong => true
    Settings.define :map,              :description => "run the script's map phase. Reads/writes to STDIN/STDOUT.", :wukong => true
    Settings.define :reduce,           :description => "run the script's reduce phase. Reads/writes to STDIN/STDOUT. You can only choose one of --run, --map or --reduce.", :wukong => true
    Settings.define :run,              :description => "run the script's main phase. In hadoop mode, invokes the hadoop script; in local mode, runs your_script.rb --map | sort | your_script.rb --reduce", :wukong => true
    Settings.define :local,            :description => "run in local mode (invokes 'your_script.rb --map | sort | your_script.rb --reduce'", :wukong => true
    Settings.define :hadoop,           :description => "run in hadoop mode (invokes the system hadoop runner script)", :wukong => true
    Settings.define :dry_run,          :description => "echo the command that will be run, but don't run it", :wukong => true

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
      self.options = Settings.dup
      options.resolve!
      options.merge! extra_options
      self.mapper_klass  = mapper_klass
      self.reducer_klass = reducer_klass
      # If no reducer_klass and no reduce_command, then skip the reduce phase
      options[:reduce_tasks] = 0 if (! reducer_klass) && (! options[:reduce_command]) && (! options[:reduce_tasks])
    end

    #
    # Gives default options.  Command line parameters take precedence
    #
    # MAKE SURE YOU CALL SUPER: write your script according to the pattern
    #
    #   super.merge :my_option => :val
    #
    def default_options
      {}
    end

    #
    # by default, call this script in --map mode
    #
    def map_command
      case
      when mapper_klass
        "#{ruby_interpreter_path} #{this_script_filename} --map " + non_wukong_params
      else options[:map_command] || options[:default_mapper] end
    end

    #
    # Shell command for reduce phase
    # by default, call this script in --reduce mode
    #
    def reduce_command
      case
      when reducer_klass
        "#{ruby_interpreter_path} #{this_script_filename} --reduce " + non_wukong_params
      else options[:reduce_command] || options[:default_reducer] end
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
      return 'local'  if options[:local]
      return 'hadoop' if options[:hadoop]
      # if only --run is given, assume default run mode
      options[:run] = options[:default_run_mode] if (options[:run] == true)
      options[:run].to_s
    end

    def input_output_paths
      # input / output paths
      input_path, output_path = options.rest[0..1]
      raise "You need to specify a parsed input directory and a directory for output. Got #{ARGV.inspect}" if (! options[:dry_run]) && (input_path.blank? || output_path.blank?)
      [input_path, output_path]
    end

    def maybe_overwrite_output_paths! output_path
      if (options[:overwrite] || options[:rm]) && (run_mode != 'local')
        $stderr.puts "Removing output file #{output_path}"
        `hdp-rm -r '#{output_path}'`
      end
    end

    # Reassemble all the non-internal-to-wukong options into a command line for
    # the map/reducer phase scripts
    def non_wukong_params
      options.
        reject{|param, val| options.param_definitions[param][:wukong] }.
        map{|param,val| "--#{param}=#{val}" }.
        join(" ")
    end

    # the full, real path to the script file
    def this_script_filename
      Pathname.new($0).realpath
    end

    # use the full ruby interpreter path to run slave processes
    def ruby_interpreter_path
      Pathname.new(
                   File.join(Config::CONFIG["bindir"],
                             Config::CONFIG["RUBY_INSTALL_NAME"]+
                             Config::CONFIG["EXEEXT"])
                   ).realpath
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
        options.dump_help %Q{Please specify a run mode: you probably want to start with
  #{$0} --run --local input.tsv output.tsv
although
  cat input.tsv | #{$0} --map > mapped.tsv
or
  cat mapped.tsv | sort | #{$0} --reduce > reduced.tsv
can be useful for initial testing.}
      end
    end
  end

end
