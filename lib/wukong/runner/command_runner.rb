module Wukong
  class Runner

    # Provides methods for executing commandlines.
    module CommandRunner

      private

      # Execute a command composed of the given parts.
      #
      # Will print the command instead if the <tt>--dry_run</tt>
      # option was given.
      #
      # Will *not* raise an error if the command fails.
      #
      # @param [Array<String>] argv
      def execute_command(*argv)
        command = argv.flatten.reject(&:blank?).join(" \\\n    ")
        if settings[:dry_run]
          log.info("Dry run:")
          puts command
        else
          puts `#{command}`
        end
      end

      # Execute a command composed of the given parts.
      #
      # Will print the command instead if the <tt>--dry_run</tt>
      # option was given.
      #
      # *Will* raise an error if the command fails.
      #
      # @param [Array<String>] argv
      def execute_command!(*argv)
        execute_command(argv)
        raise Error.new("Command failed!") unless $?.success?
      end
      
    end

  end
end
