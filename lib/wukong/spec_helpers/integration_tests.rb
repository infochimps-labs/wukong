require 'open3'
require_relative('integration_tests/integration_test_runner')
require_relative('integration_tests/integration_test_matchers')

module Wukong
  module SpecHelpers
    
    # This module defines methods that are helpful to use in
    # integration tests which require reading files from the local
    # repository.
    #
    # 
    module IntegrationTests

      def lib_dir *args
        root.join('lib', *args).to_s
      end

      def bin_dir *args
        root.join('bin', *args).to_s
      end
      
      def examples_dir *args
        root.join('examples', *args).to_s
      end

      def integration_env
        {
          "PATH"    => [bin_dir.to_s, ENV["PATH"]].compact.join(':'),
          "RUBYLIB" => [lib_dir.to_s, ENV["RUBYLIB"]].compact.join(':')
        }
      end

      def integration_cwd
        root.to_s
      end

      # Checks that each `expectation` appears in the STDOUT of the
      # command.  Order is irrelevant and each `expectation` can be
      # either a String to check for inclusion or a Regexp to match
      # with.
      #
      # @param [Array<String,Regexp>] expectations
      def have_stdout *expectations
        StdoutMatcher.new(*expectations)
      end

      # Checks that each `expectation` appears in the STDERR of the
      # command.  Order is irrelevant and each `expectation` can be
      # either a String to check for inclusion or a Regexp to match
      # with.
      #
      # @param [Array<String,Regexp>] expectations
      def have_stderr *expectations
        StderrMatcher.new(*expectations)
      end

      # Checks that the command exits with the given `code`.
      #
      # @param [Integer] code
      def exit_with code
        ExitCodeMatcher.new(code)
      end
      
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

        IntegrationTestRunner.new(a, cwd: cwd, env: env)
      end
    end
  end
end
