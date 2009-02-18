require 'pathname'
require 'wukong/script/hadoop_command'
require 'wukong/script/local_command'
module Wukong

  # == How to run a Wukong script
  #
  #   your/script.rb --go path/to/input_files path/to/output_dir
  #
  # All of the file paths are HDFS paths ; your script path, of course, is on the local filesystem.
  #
  # == Command-line options
  #
  # If you'd like to listen for any command-line options, specify them at the
  # command line:
  #
  #   your/script.rb --my_bool_opt --my_val_taking_opt=val \
  #     --go path/to/input_files path/to/output_dir
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
  # == Run locally (--fake)
  #
  # To run your script locally, supply the --fake argument:
  #
  #   your/script.rb --fake path/to/input_files path/to/output_dir
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
  # You can supply the --map argument in place of --go to run the mapper on its
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
    def initialize mapper_klass, reducer_klass
      self.options = default_options
      process_argv!
      self.mapper_klass  = mapper_klass
      self.reducer_klass = reducer_klass
    end


    #
    # Gives default options.  Command line parameters take precedence
    #
    # MAKE SURE YOU CALL SUPER: write your script according to the patter
    #
    #   super.merge :my_option => :val
    #
    def default_options
      CONFIG[:runner_defaults]
    end

    #
    # Parse the command-line args into the options hash.
    #
    # I should not reinvent the wheel.
    # Yet here we are.
    #
    def process_argv!
      options[:all_args] = ARGV - ['--go']
      args = ARGV.dup
      while args do
        arg = args.shift
        case
        when arg == '--' then break
        when arg =~ /\A--(\w+)(?:=(.+))?\z/
          opt, val = [$1, $2]
          opt = opt.to_sym
          val ||= true
          self.options[opt] = val
        else args.unshift(arg) ; break
        end
      end
      self.options[:rest] = args
      # $stderr.puts [ self.options, this_script_filename.to_s ].inspect
    end

    def this_script_filename
      Pathname.new($0).realpath
    end

    #
    # by default, call this script in --map mode
    #
    def map_command
      case
      when mapper_klass
        "#{this_script_filename} --map " + options[:all_args].join(" ")
      else CONFIG[:default_mapper] end
    end

    #
    # Shell command for reduce phase
    # by default, call this script in --reduce mode
    #
    def reduce_command
      case
      when reducer_klass
        "#{this_script_filename} --reduce " + options[:all_args].join(" ")
      else CONFIG[:default_reducer] end
    end

    #
    # Execute the runner phase
    #
    def exec_hadoop_streaming
      slug = Time.now.strftime("%Y%m%d")
      input_path, output_path = options[:rest][0..1]
      raise "You need to specify a parsed input directory and a directory for output. Got #{ARGV.inspect}" if (! options[:fake]) && (input_path.blank? || output_path.blank?)

      $stderr.puts "Streaming on self"
      # if only --run is given, assume default run mode
      options[:run] = CONFIG[:default_run_mode] if (options[:run] == true)
      # run as either local or hadoop
      case options[:run].to_s
      when 'local'
        $stderr.puts "  Reading STDIN / Writing STDOUT"
        command = local_command input_path, output_path
      when 'hadoop', 'mapred'
        $stderr.puts "  Launching hadoop as"
        command = hadoop_command input_path, output_path
      else
        raise "Need to use --run=local or --run=hadoop; or to use the :default_run_mode in config.yaml just say --run "
      end
      $stderr.puts command
      if ! options[:fake]
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
        #{__FILE__} --go input_hdfs_path output_hdfs_dir     # run the script with hadoop streaming
        #{__FILE__} --map,
        #{__FILE__} --reduce                                 # dispatch to the mapper or reducer
      }
    end
  end

end
