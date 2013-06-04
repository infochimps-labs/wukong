require_relative 'stdio_driver'

module Wukong
  module Local

    # Implements the Runner for wu-local.
    class LocalRunner < Wukong::Runner

      include Wukong::Logging

      usage "PROCESSOR|FLOW"
      
      description <<-EOF.gsub(/^ {8}/, '')
        wu-local is a tool for running Wukong processors and flows locally on
        the command-line.  Use wu-local by passing it a processor and feeding
        in some data:

          $ echo 'UNIX is Clever and Fun...' | wu-local tokenizer.rb
          UNIX
          is
          Clever
          and
          Fun

        If your processors have named fields you can pass them in as
        arguments:

          $ echo 'UNIX is clever and fun...' | wu-local tokenizer.rb --min_length=4
          UNIX
          Clever

        You can chain processors and calls to wu-local together:

          $ echo 'UNIX is clever and fun...' | wu-local tokenizer.rb --min_length=4 | wu-local downcaser.rb
          unix
          clever

        Which is a good way to develop a combined data flow which you can
        again test locally:

          $ echo 'UNIX is clever and fun...' | wu-local tokenize_and_downcase_big_words.rb
          unix
          clever
      EOF

      # Returns the name of the dataflow we're going to run.
      #
      # @return [String]
      def dataflow
        arg      = args.first
        basename = File.basename(arg.to_s, '.rb')

        case
        when settings[:run]          then settings[:run]
        when arg && File.exist?(arg) then basename
        else arg
        end
      end
      alias_method :processor, :dataflow

      # Validates the chosen processor.
      #
      # @raise [Wukong::Error] if it finds a problem
      # @return [true]
      def validate
        raise Error.new("Must provide a processor or dataflow to run, via either the --run option or as the first argument") if dataflow.nil? || dataflow.empty?
        raise Error.new("No such processor or dataflow <#{dataflow}>") unless registered?(dataflow)
        true
      end

      # Adds a customized help message built from the Processor
      # # itself.
      def setup
        super()
        dataflow_class_for(dataflow).configure(settings) if registered?(dataflow)
      end

      # Starts up the driver with the right dataflow and settings.
      #
      # Starts the EventMachine reactor before starting the driver.
      def run
        EM.run do
          driver.start(dataflow, settings)
        end
      end

      # The class used 
      #
      # @return [Class, #start]
      def driver
        StdioDriver
      end
      
    end
  end
end
