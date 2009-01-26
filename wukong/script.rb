require 'pathname'
module Hadoop
  class Script
    attr_accessor :mapper_klass, :reducer_klass, :options
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

    def map_tasks()  options[:map_tasks]  end

    def extra_args
      a = []
      a << "-jobconf mapred.map.tasks=#{map_tasks}"       if map_tasks
      a << "-jobconf mapred.reduce.tasks=#{options[:reduce_tasks]}" if options[:reduce_tasks]
      a << "-jobconf num.key.fields.for.partition=#{options[:partition_keys]}" if options[:partition_keys]
      a << "-jobconf stream.num.map.output.key.fields=#{options[:sort_keys]}"   if options[:sort_keys]
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
        command = %Q{ #{map_command} | sort | #{reduce_command} }
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
      when options[:fake_hadoop]
        exec_fake_hadoop
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
