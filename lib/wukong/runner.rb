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


  class HadoopRunner
    include  RunnerWithInputOutput
    executor which('hadoop')

    argument :verbose,      Boolean,  :native => '-v', :solo => true, :doc => 'show files as they are copied'

  end

end
