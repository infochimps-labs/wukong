require 'pathname'
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
      process_argv!
      self.mapper_klass  = mapper_klass
      self.reducer_klass = reducer_klass
    end

    #
    # Parse the command-line args into the options hash.
    #
    # I should not reinvent the wheel.
    # Yet here we are.
    #
    def process_argv!
      self.options = { }
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
      else '/bin/cat' end
    end

    #
    # Shell command for reduce phase
    # by default, call this script in --reduce mode
    #
    def reduce_command
      case
      when reducer_klass
        "#{this_script_filename} --reduce " + options[:all_args].join(" ")
      else '/bin/cat' end
    end

    #
    # Number of fields for the KeyBasedPartitioner
    # to sort on.
    #
    def sort_fields
      self.options[:sort_fields] || 2
    end

    def map_tasks()     options[:map_tasks]  end
    def reduce_tasks()  options[:reduce_tasks]  end

    def extra_args
      a = []
      a << "-jobconf mapred.map.tasks=#{map_tasks}"                                    if map_tasks
      a << "-jobconf mapred.reduce.tasks=#{options[:reduce_tasks]}"                    if reduce_tasks
      a << "-jobconf mapred.tasktracker.map.tasks.maximum=#{options[:map_tasks_max]}"  if options[:map_tasks_max]
      a << "-jobconf num.key.fields.for.partition=#{options[:partition_keys]}"         if options[:partition_keys]
      a << "-jobconf stream.num.map.output.key.fields=#{options[:sort_keys]}"          if options[:sort_keys]
      a.join(" ")
    end

    def exec_hadoop_streaming
      slug = Time.now.strftime("%Y%m%d")
      input_path, output_path = options[:rest][0..1]
      raise "You need to specify a parsed input directory and a directory for output. Got #{ARGV.inspect}" if (! options[:fake]) && (input_path.blank? || output_path.blank?)
      $stderr.puts "Launching hadoop streaming on self"
      case
      when options[:fake]
        $stderr.puts "Reading STDIN / Writing STDOUT"
        command = %Q{ cat '#{input_path}' | #{map_command} | sort | #{reduce_command} > '#{output_path}'}
      when options[:nopartition]
        command = %Q{ hdp-stream-flat '#{input_path}' '#{output_path}' '#{map_command}' '#{reduce_command}' #{extra_args} }
      else
        command = %Q{ hdp-stream '#{input_path}' '#{output_path}' '#{map_command}' '#{reduce_command}' #{sort_fields} #{extra_args} }
      end
      # $stderr.puts options.inspect
      $stderr.puts command
      $stdout.puts `#{command}`
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
      when options[:go]
        exec_hadoop_streaming
      # when options[:fake]
      #   exec_fake_hadoop
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
