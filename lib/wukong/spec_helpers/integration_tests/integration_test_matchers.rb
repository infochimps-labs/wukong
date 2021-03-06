module Wukong
  module SpecHelpers
    
    # A class for running commands and capturing their STDOUT, STDERR,
    # and exit code.  This class is designed to work with the matchers
    # defined in IntegrationTestMatchers.
    class IntegrationTestMatcher

      # The runner used to run the actual commands.
      attr_accessor :runner

      # An array of expectations about the output of the runner.
      attr_accessor :expectations

      # The expectation which caused failure.
      attr_accessor :failed_expectation

      # Return whether or not the given command's output matches
      # expectations.
      #
      # If an expectation failes to match, the `failed_expectation`
      # attribute will be set accordingly.
      #
      # @param [IntegrationTestRunner] runner
      # @return [true, false]
      def matches?(runner)
        self.runner = runner
        runner.run!
        expectations.each do |expectation|
          unless output.send(match_function(expectation), expectation)
            self.failed_expectation = expectation
            return false
          end
        end
        true
      end

      # Create a matcher on the given expectations.  Each expectation
      # can be either a String or a Regexp.  Strings will be tested
      # for inclusion in the output, Regexps will be tested for a
      # match against the output.
      #
      # @param [Array<String,Regexp>] expectations
      def initialize *expectations
        self.expectations = expectations
      end

      # :nodoc:
      def failure_message
        "From within #{runner.cwd} ran\n\n#{formatted_env}\n#{formatted_command}\n\nand expected #{output_description}\n\n#{formatted_output}\n\nto #{match_type}\n\n  #{failed_expectation}#{formatted_error_output}"
      end

      # :nodoc:
      def negative_failure_message
        "Expected #{output_description} of #{runner.cmd}\n\n#{output}\n\nto NOT #{match_type}\n\n#{self.failed_expectation}."
      end

      # :nodoc:
      def formatted_output
        output.split("\n").map { |line| '  ' + line }.join("\n")
      end

      # :nodoc:
      def formatted_error_output
        output_description.to_s =~ /stderr/ ? "\n\nSTDOUT was\n\n#{runner.stdout}" : "\n\nSTDERR was\n\n#{runner.stderr}"
      end

      # :nodoc:
      def formatted_command
        "  $ #{runner.cmd}"
      end

      # :nodoc:
      def formatted_env
        ['  {'].tap do |lines|
          runner.env.each_pair do |key, value|
            if key =~ /^(BUNDLE_GEMFILE|PATH|RUBYLIB)$/
              lines << "    #{key} => #{value},"
            end
          end
          lines << '  }'
        end.join("\n")
      end

      # :nodoc:
      def match_function expectation
        expectation.is_a?(Regexp) ? :match : :include?
      end

      # :nodoc:
      def match_type
        failed_expectation.is_a?(Regexp) ? 'match' : 'include'
      end

    end

    # A matcher for the STDOUT of a command.
    class StdoutMatcher < IntegrationTestMatcher

      # Picks the STDOUT of the command.
      def output
        runner.stdout
      end

      # :nodoc:
      def output_description
        "STDOUT"
      end

      def description
        "have the correct #{output_description}"
      end
      
    end

    # A matcher for the STDOUT of a command.
    class StderrMatcher < IntegrationTestMatcher

      # Picks the STDOUT of the command.
      def output
        runner.stderr
      end

      # :nodoc:
      def output_description
        "STDERR"
      end

      def description
        "print an appropriate error message on #{output_description}"
      end
    end

    # A matcher for the exit code of a command.
    class ExitCodeMatcher < IntegrationTestMatcher

      # Initialize this matcher with the given `code`.
      #
      # If `code` is the symbol <tt>:non_zero</tt> then the
      # expectation will be any non-zero exit code.
      #
      # @param [Integer,Symbol] code
      def initialize code
        if code ==  :non_zero
          @expected_code = :non_zero
        else
          @expected_code = code.to_i
        end
      end

      # Return whether or not the given command's exit code matches
      # the expectation.
      #
      # @param [IntegrationTestRunner] runner
      # @return [true, false]
      def matches?(runner)
        self.runner = runner
        runner.run!
        if non_zero_exit_code?
          @failed = true if runner.exit_code == 0
        else
          @failed = true if runner.exit_code != expected_exit_code
        end
        @failed ? false : true
      end

      # :nodoc:
      def failure_message
        "From within #{runner.cwd} ran\n\n#{formatted_env}\n#{formatted_command}\n\nexpecting #{expected_exit_code_description}  Got #{runner.exit_code} instead.#{formatted_error_output}"
      end

      # :nodoc:
      def negative_failure_message
        "From within #{runner.cwd} ran\n\n#{formatted_env}\n#{formatted_command}\n\nNOT expecting #{expected_exit_code_description}.#{formatted_error_output}"
      end

      # :nodoc:
      def non_zero_exit_code?
        @expected_code == :non_zero
      end

      # :nodoc:
      def expected_exit_code
        (@expected_code || 0).to_i
      end

      # :nodoc:
      def expected_exit_code_description
        if non_zero_exit_code?
          "a non-zero exit code"
        else
          "an exit code of #{expected_exit_code}"
        end
      end

      # :nodoc:
      def description
        "exit with #{expected_exit_code_description}"
      end

      # :nodoc:
      def output_description
        "STDOUT"
      end
    end
  end
end
