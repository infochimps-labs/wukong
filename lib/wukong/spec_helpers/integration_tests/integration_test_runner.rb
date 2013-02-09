require 'open3'

module Wukong
  module SpecHelpers
    
    # A runner for running commands in a subprocess.
    class IntegrationTestRunner

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
        FileUtils.cd(cwd) do
          Open3.popen3(env, cmd) do |i, o, e, wait_thr|
            self.pid = wait_thr.pid
            
            @inputs.each { |input| i.puts(input) }
            i.close
            
            self.stdout    = o.read
            self.stderr    = e.read
            self.exit_code = wait_thr.value.to_i
          end
        end
        @ran = true
      end

      # Initialize a new IntegrationTestRunner to run a given command.
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
      alias_method :<, :on

      def in dir
        @cwd = dir
        self
      end

      def using env
        @env = env
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
