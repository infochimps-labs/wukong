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

      # Returns the name of the processor we're going to run.
      #
      # @return [String]
      def processor
        arg      = args.first
        basename = File.basename(arg.to_s, '.rb')

        case
        when settings[:run]          then settings[:run]
        when arg && File.exist?(arg) then basename
        else arg
        end
      end

      # Validates the chosen processor.
      #
      # @raise [Wukong::Error] if it finds a problem
      # @return [true]
      def validate
        raise Error.new("Must provide a processor or dataflow to run, via either the --run option or as the first argument") if processor.nil? || processor.empty?
        raise Error.new("No such processor or dataflow <#{processor}>") unless registered?(processor)
        true
      end

      # Adds a customized help message built from the Processor
      # # itself.
      def setup
        super()
        dataflow_class_for(processor).configure(settings) if processor?(processor)
      end

      # Runs either the StdioDriver or the TCPDriver, depending on
      # what settings were passed.
      def run
        EM.run do
          driver.start(processor, settings)
        end
      end

      # :nodoc:
      def driver
        StdioDriver
      end
      
    end
  end
end
