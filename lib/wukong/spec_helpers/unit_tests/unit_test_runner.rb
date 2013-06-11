module Wukong
  module SpecHelpers

    # A class for controlling the Wukong boot sequence from within
    # unit tests.
    #
    # Subclasses the Wukong::Local::LocalRunner with which it shares
    # most of its behavior:
    #
    # * Initialization is slightly different, to allow for each
    #   separate unit test in a suite to use a different
    #   Configliere::Param object for settings
    #   
    # * The driver is the UnitTestDriver instead of the usual driver
    #   to allow for easily passing in records and getting them back
    #   out
    #
    # * The `run` method is a no-op so that control flow will exit out
    #   of the unit test back into the test suite
    class UnitTestRunner < Wukong::Local::LocalRunner

      # Initialize a new UnitTestRunner for the processor with the
      # given `label` and `settings`.
      #
      # @param [Symbol] label
      # @param [Hash] settings
      def initialize label, settings={}
        @dataflow = label
        params = Configliere::Param.new
        params.merge!(settings)
        super(params)
      end

      def dataflow
        @dataflow
      end

      # Override the LocalDriver with the UnitTestDriver so we can
      # more easily pass in and retrieve processed records.
      #
      # @return [UnitTestDriver]
      def driver
        @driver ||= UnitTestDriver.new(dataflow, settings)
      end

      # No need to load commandline arguments when we are testing
      # There are other mechanisms for passing them in, plus
      # RSpec goes into an infinite loop if you load a spec file
      # from within a spec file
      def load_args
      end

      # Do nothing.  This prevents control flow within the Ruby
      # interpreter from staying within this runner, as it would
      # ordinarly do for `wu-local`.
      def run
      end
    end
  end
end
