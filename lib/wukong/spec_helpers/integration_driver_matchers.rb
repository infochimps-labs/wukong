module Wukong
  module SpecHelpers

    # Provides matchers for STDOUT, STDERR, and exit code when writing
    # integration tests for Wukong's command-line APIs.
    module IntegrationMatchers

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

    end

    # A class for running commands and capturing their STDOUT, STDERR,
    # and exit code.  This class is designed to work with the matchers
    # defined in IntegrationMatchers.
    class IntegrationMatcher

      # The driver used to run the actual commands.
      attr_accessor :driver

      # An array of expectations about the output of the driver.
      attr_accessor :expectations

      # The expectation which caused failure.
      attr_accessor :failed_expectation

      # Return whether or not the given command's output matches
      # expectations.
      #
      # If an expectation failes to match, the `failed_expectation`
      # attribute will be set accordingly.
      #
      # @param [IntegrationDriver] driver
      # @return [true, false]
      def matches?(driver)
        self.driver = driver
        driver.run!
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
        "Ran\n\n  #{formatted_command}\n\nand expected #{output_description}\n\n#{formatted_output}\n\nto #{match_type}\n\n  #{failed_expectation}"
      end

      # :nodoc:
      def negative_failure_message
        "Expected #{output_description} of #{driver.cmd}\n\n#{output}\n\nto NOT #{match_type}\n\n#{self.failed_expectation}."
      end

      # :nodoc:
      def formatted_output
        output.split("\n").map { |line| '  ' + line }.join("\n")
      end

      # :nodoc:
      def formatted_command
        "$ #{driver.cmd}"
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
    class StdoutMatcher < IntegrationMatcher

      # Picks the STDOUT of the command.
      def output
        driver.stdout
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
    class StderrMatcher < IntegrationMatcher

      # Picks the STDOUT of the command.
      def output
        driver.stderr
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
    class ExitCodeMatcher < IntegrationMatcher

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
      # @param [IntegrationDriver] driver
      # @return [true, false]
      def matches?(driver)
        self.driver = driver
        driver.run!
        if non_zero_exit_code?
          @failed = true if driver.exit_code == 0
        else
          @failed = true if driver.exit_code != expected_exit_code
        end
        @failed ? false : true
      end

      # :nodoc:
      def failure_message
        "Ran\n\n  #{formatted_command}\n\nexpecting #{expected_exit_code_description}  Got #{driver.exit_code} instead."
      end

      # :nodoc:
      def negative_failure_message
        "Ran\n\n  #{formatted_command}\n\nNOT expecting #{expected_exit_code_description}."
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

    end
  end
end
