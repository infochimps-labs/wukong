module Wukong
  class Runner

    # Defines methods for handling help messages.
    #
    # Runners which want to modify how help messages are generated
    # should override the `contextualize_help_message!` instance method.
    module HelpMessage

      # Was the `--help` option specified on the command line?
      #
      # The boot sequence for a Runner strips out the `--help` option to
      # allow individual Runner classes to customize their help
      # messages.
      #
      # @return [true, false]
      def help_given?
        !!@help_given
      end

      # Strip the `--help` message from the original ARGV, storing
      # whether or not it was given for later.
      def strip_help_param!
        @help_given = ARGV.delete('--help')
      end

      # Print a help message.
      def dump_help
        settings.dump_help
      end

      # Print a help message and exit.
      #
      # @raise [SystemExit]
      def dump_help_and_exit!
        dump_help
        exit(1)
      end
        
    end
  end
end
