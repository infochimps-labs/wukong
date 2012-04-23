require 'wukong'
require 'wukong/script/hadoop_command'

#
# Runner settings
#

Settings.define :mode, :type => Symbol, :default => :mapper, :env_var => 'WUKONG_MODE',  :description => "run the script's workflow: Specify 'hadoop' to use hadoop streaming; 'local' to run your_script.rb --map | sort | your_script.rb --reduce; 'emr' to launch on the amazon cloud; 'mapper' or 'reducer' to run that phase.", :wukong => true
Settings.define :dry_run,  :description => "echo the command that will be run, but don't run it", :wukong => true
Settings.define :rm,       :description => "Recursively remove the destination directory. Only used in hadoop mode.", :wukong => true
Settings.define :script_file, :type => :filename, :description => "script file to execute, or give as first arg", :wukong => true

module Wukong
  # adds ability to execute
  extend Wukong::Mixin::FromFile

  #
  # sources a script file,
  #
  class Script
    attr_reader :settings     # configliere hash of settings
    attr_reader :script_file  # File to execute
    attr_reader :input_paths
    attr_reader :output_path

    include Wukong::Script::HadoopCommand

    def initialize(settings)
      @settings = settings

      @output_path = settings.rest.pop
      @input_paths = settings.rest.reject(&:blank?)
    end


    # Execute the script file in the context of the Wukong module
    def run_flow
      Log.debug( "Running #{script_file} with settings #{settings}")
      script_file = settings.script_file
      mode        = settings.mode
      Wukong.flow(mode).run
    end

    #
    # In --run mode, use the framework (local, hadoop, emr, etc) to re-launch
    #   the script as mapper, reducer, etc.
    # If --map or --reduce, dispatch to the mapper or reducer.
    #
    def run
      case settings.mode
      when :local            then execute_local_workflow
      when :hadoop, :mapred then execute_hadoop_workflow
      else
        run_flow
      end
    end

    #
    # Shell command for map phase. By default, calls the script in --map mode
    # In hadoop mode, this is given to the hadoop streaming command.
    # In local mode, it's given to the system() call
    #
    def mapper_commandline
      "#{ruby_interpreter_path} #{this_script_filename} --mode=mapper " + non_wukong_params
    end

    #
    # Shell command for reduce phase. By default, calls the script in --reduce mode
    # In hadoop mode, this is given to the hadoop streaming command.
    # In local mode, it's given to the system() call
    #
    def reducer_commandline
      "#{ruby_interpreter_path} #{this_script_filename} --mode=reducer " + non_wukong_params
    end

    def job_name
      settings[:job_name] ||
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
      if settings[:dry_run]
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
      if (settings.rm && (settings.mode == :hadoop))
        cmd = %Q{#{hadoop_runner} fs -rmr '#{output_path}'}
        Log.info "Removing output file #{output_path}: #{cmd}"
        puts `#{cmd}`
      end
    end

    # Reassemble all the non-internal-to-wukong settings into a command line for
    # the map/reducer phase scripts
    def non_wukong_params
      settings.
        reject{|param, val| settings.definition_of(param, :wukong) }.
        reject{|param, val| param.to_s =~ /catalog_root/ }.
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


  end
end
