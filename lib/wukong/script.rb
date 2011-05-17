require 'pathname'
require 'wukong/extensions'
require 'configliere' ; Settings.use(:commandline, :env_var, :define)
require 'wukong'
require 'wukong/script/hadoop_command'
require 'wukong/script/local_command'
require 'rbconfig' # for uncovering ruby_interpreter_path
require 'wukong/streamer' ; include Wukong::Streamer
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
  # == Run in Elastic MapReduce Mode (--run=emr)
  #
  # Wukong can be used to start scripts on the amazon cloud
  #
  # * copies the script to s3 in two parts
  # * invokes it using the amazon API
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
    attr_reader :mapper, :reducer, :options
    attr_reader :input_paths, :output_path

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
    Settings.define :default_run_mode,   :default => 'hadoop', :description => 'Run mode: local, hadoop, emr (elastic mapreduce)', :wukong => true, :hide_help => false
    Settings.define :map_command,                              :description => "shell command to run as mapper, in place of this wukong script", :wukong => true
    Settings.define :reduce_command,                           :description => "shell command to run as reducer, in place of this wukong script", :wukong => true
    Settings.define :run,      :env_var => 'WUKONG_RUN_MODE',    :description => "run the script's workflow: Specify 'hadoop' to use hadoop streaming; 'local' to run your_script.rb --map | sort | your_script.rb --reduce; 'emr' to launch on the amazon cloud; 'map' or 'reduce' to run that phase.", :wukong => true
    Settings.define :map,                                      :description => "run the script's map phase. Reads/writes to STDIN/STDOUT.", :wukong => true
    Settings.define :reduce,                                   :description => "run the script's reduce phase. Reads/writes to STDIN/STDOUT. You can only choose one of --run, --map or --reduce.", :wukong => true
    Settings.define :dry_run,                                  :description => "echo the command that will be run, but don't run it", :wukong => true
    Settings.define :rm,                                       :description => "Recursively remove the destination directory. Only used in hadoop mode.", :wukong => true

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
    def initialize mapper, reducer=nil, extra_options={}
      Settings.resolve!
      @options = Settings
      options.merge! extra_options
      @mapper  = (case mapper  when Class then mapper.new  when nil then nil else mapper  ; end)
      @reducer = (case reducer when Class then reducer.new when nil then nil else reducer ; end)
      @output_path = options.rest.pop
      @input_paths = options.rest.reject(&:blank?)
      if (input_paths.blank? || output_path.blank?) && (not options[:dry_run]) && (not ['map', 'reduce'].include?(run_mode))
        raise "You need to specify a parsed input directory and a directory for output. Got #{ARGV.inspect}"
      end
    end

    #
    # In --run mode, use the framework (local, hadoop, emr, etc) to re-launch
    #   the script as mapper, reducer, etc.
    # If --map or --reduce, dispatch to the mapper or reducer.
    #
    def run
      case run_mode
      when 'map'              then mapper.stream
      when 'reduce'           then reducer.stream
      when 'local'            then execute_local_workflow
      when 'cassandra'        then execute_hadoop_workflow
      when 'hadoop', 'mapred' then execute_hadoop_workflow
      when 'emr'
        require 'wukong/script/emr_command'
        execute_emr_workflow
      else                    dump_help
      end
    end

    # if only --run is given, assume default run mode
    def run_mode
      case
      when options[:map]           then 'map'
      when options[:reduce]        then 'reduce'
      when ($0 =~ /-mapper\.rb$/)  then 'map'
      when ($0 =~ /-reducer\.rb$/) then 'reduce'
      when (options[:run] == true) then options[:default_run_mode]
      else                         options[:run].to_s
      end
    end

    #
    # Shell command for map phase. By default, calls the script in --map mode
    # In hadoop mode, this is given to the hadoop streaming command.
    # In local mode, it's given to the system() call
    #
    def mapper_commandline(run_option=:local)
      if mapper
        case run_option
        when :local then
          "#{ruby_interpreter_path} #{this_script_filename} --map " + non_wukong_params
        when :hadoop then
          "#{ruby_interpreter_path} #{File.basename(this_script_filename)} --map " + non_wukong_params
        end
      else
        options[:map_command]
      end
    end

    #
    # Shell command for reduce phase. By default, calls the script in --reduce mode
    # In hadoop mode, this is given to the hadoop streaming command.
    # In local mode, it's given to the system() call
    #
    def reducer_commandline(run_option=:local)
      if reducer
        case run_option
        when :local then
          "#{ruby_interpreter_path} #{this_script_filename} --reduce " + non_wukong_params
        when :hadoop then
          "#{ruby_interpreter_path} #{File.basename(this_script_filename)} --reduce " + non_wukong_params
        end
      else
        options[:reduce_command]
      end
    end

    def job_name
      options[:job_name] ||
        "#{File.basename(this_script_filename)}---#{input_paths}---#{output_path}".gsub(%r{[^\w/\.\-\+]+}, '')
    end

    # Wrapper for dangerous operations to catch errors
    def safely action, &block
      begin
        block.call
      rescue StandardError => e ; handle_error(action, e); end
    end

  protected

    #
    # Execute the runner phase:
    # use the running framework to relaunch the script in map and in reduce mode
    #
    def execute_command! *args
      command = args.flatten.reject(&:blank?).join(" \\\n    ")
      Log.info "Running\n\n#{command}\n"
      if options[:dry_run]
        Log.info '== [Not running preceding command: dry run] =='
      else
        maybe_overwrite_output_paths! output_path
        $stdout.puts `#{command}`
        raise "Streaming command failed!" unless $?.success?
      end
    end

    #
    # In hadoop mode only, removes the destination path before launching
    #
    # To the panic-stricken: look in .Trash/current/path/to/accidentally_deleted_files
    #
    def maybe_overwrite_output_paths! output_path
      if (options[:overwrite] || options[:rm]) && (run_mode == 'hadoop')
        cmd = %Q{#{hadoop_runner} fs -rmr '#{output_path}'}
        Log.info "Removing output file #{output_path}: #{cmd}"
        puts `#{cmd}`
      end
    end

    # Reassemble all the non-internal-to-wukong options into a command line for
    # the map/reducer phase scripts
    def non_wukong_params
      options.
        reject{|param, val| options.definition_of(param, :wukong) }.
        map{|param,val| "--#{param}=#{val}" }.
        join(" ")
    end

    # the full, real path to the script file
    def this_script_filename
      Pathname.new($0).realpath
    end

    # use the full ruby interpreter path to run slave processes
    def ruby_interpreter_path
      Pathname.new(File.join(
          Config::CONFIG["bindir"],
          Config::CONFIG["RUBY_INSTALL_NAME"]+Config::CONFIG["EXEEXT"])).realpath
    end

    #
    # Usage
    #
    def dump_help
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
