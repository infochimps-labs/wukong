require 'open3'

module Wukong
  module SpecHelpers

    # Provides a `command` method for writing integration tests for
    # commands.
    module IntegrationRunner

      # Spawn a command and capture its STDOUT, STDERR, and exit code.
      #
      # The `args` will be joined together into a command line.
      #
      # It is expected that you will use the matchers defined in
      # IntegrationMatchers in your integration tests:
      #
      # @example Check output of 'ls' includes a string 'foo.txt'
      #   it "lists files" do
      #     command('ls').should have_output('foo.txt')
      #   end
      #
      # @example More complicated
      #   context "long format" do
      #     it "lists files with timestamps" do
      #       command('ls', '-l').should have_output('foo.txt', /\w+ \d+ \d+:\d+/)
      #     end
      #   end
      #
      # @param [Array<String>] args
      #
      # @overload command(*args, options={})
      #   If the last element of `args` is a Hash it will be used for
      #   options.
      #
      #   The :env option specifies the command line environment to
      #   use for the command.  By default this will be the value of
      #   the Ruby process's own `ENV` variable.  If running in a
      #   context in which the `integration_env` method is defined,
      #   its return value will be merged on top of `ENV`.  An
      #   explicitly provided :env option will again be merged on top.
      #
      #   The :cwd option specifies the working directory to start in.
      #   It defaults to the value of <tt>Dir.pwd</tt>
      #
      #   @param [Array<String>] args
      #   @param [Hash] options
      #   @option options [Hash] env the shell environment to spawn the command with
      #   @option options [Hash] cwd the directory to execute the command in
      def command *args
        a = args.flatten.compact
        options = (a.last.is_a?(Hash) ? a.pop : {})

        env = ENV.to_hash.dup
        env.merge!(integration_env) if respond_to?(:integration_env)
        env.merge!(options[:env] || {})

        cwd   = options[:cwd]
        cwd ||= (respond_to?(:integration_cwd) ? integration_cwd : Dir.pwd)

        IntegrationDriver.new(a, cwd: cwd, env: env)
      end
    end

    # A driver for running commands in a subprocess.
    class IntegrationDriver

      # The command to execute
      attr_accessor :cmd
      
      # The directory in which to execute the command.
      attr_accessor :cwd

      # The ID of the spawned subprocess (while it was running).
      attr_accessor :pid

      # The STDOUT of the spawned process.
      attr_accessor :stdout

      # The STDERR of the spawned process.
      attr_accessor :stderr

      # The exit code of the spawned process.
      attr_accessor :exit_code

      # Run the command and capture its outputs and exit code.
      #
      # @return [true, false]
      def run!
        return false if ran?
        Open3.popen3(env, cmd) do |i, o, e, wait_thr|
          self.pid = wait_thr.pid

          @inputs.each { |input| i.puts(input) }
          i.close

          self.stdout    = o.read
          self.stderr    = e.read
          self.exit_code = wait_thr.value.to_i
        end
        @ran = true
      end

      # Initialize a new IntegrationDriver to run a given command.
      def initialize args, options
        @args   = args
        @env    = options[:env]
        @cwd    = options[:cwd]
        @inputs = []
      end

      def cmd
        @args.compact.map(&:to_s).join(' ')
      end

      def on *events
        @inputs.concat(events)
        self
      end

      def env
        ENV.to_hash.merge(@env || {})
      end

      def ran?
        @ran
      end
      
      def cmd_summary
        [
         cmd,
         "with env #{env_summary}",
         "in dir #{cwd}"
        ].join("\n")
      end

      def env_summary
        { "PATH" => env["PATH"], "RUBYLIB" => env["RUBYLIB"] }.inspect
      end
      
    end
  end
end

  
