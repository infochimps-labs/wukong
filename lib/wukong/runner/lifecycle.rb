module Wukong
  class Runner

    # The lifecycle of a Runner consists of the following phases,
    # executed in sequence:
    #
    # * #load -- loads all code needed for operation
    # * #configure -- configures settings from core Wukong and all plugins
    # * #resolve -- resolves settings
    # * #setup -- boots core Wukong and all plugins
    # * #validate -- validates command-line args
    # * #run -- starts the runner running
    #
    # This module implements methods which define each of these
    # phases.  Each method can be separately overriden, allowing for a
    # lot of customizability.
    module Lifecycle
      
      # Perform the lifecycle of this Runner, calling in order:,
      # consisting of the
      #
      # * #load
      # * #configure
      # * #resolve
      # * #setup
      # * #validate
      # * #run or #die
      def perform_lifecycle(s=nil)
        load
        configure
        if resolve
          setup
          settings.merge!(s) if s
          validate ? run : die("Invalid arguments")
        end
      end

      private

      # Loads all code necessary for this Runner to perform, including:
      #
      # * any code associated with being inside of a deploy pack
      # * any code passed in as (unknown rest) arguments on the command-line
      def load
        load_deploy_pack
        load_args
      end

      # Endows the settings with everything it needs, including usage,
      # description, and any define's provided by this Runner class or
      # any plugins.
      def configure
        settings.use(:commandline)
        settings.description = description if description
        u = usage
        settings.define_singleton_method(:usage){ u } if u
        Wukong.configure_plugins(settings, program_name)
      end

      # Resolves the settings.
      #
      # Rescues some of the annoying RuntimeErrors thrown by
      # Configliere...
      def resolve
        begin
          settings.resolve!
          true
        rescue RuntimeError, SystemExit => e
          false
        end
      end
      
      # Performs any setup code necessary before run.
      #
      # Boots all plugins by default.  If you override this code, make
      # sure to either call `super` or boot plugins yourself.
      def setup
        Wukong.boot_plugins(settings, root)
      end

      # Validates the command-line args.  Raise a Wukong::Error in this
      # method to terminate execution.
      #
      # Return false-like to prevent the runner from running.
      #
      # @return [true, false]
      def validate
        true
      end
      
      # Run this runner.
      #
      # You'll want to override this method in your own Runner class.
      def run
      end

      # Kill this runner with the given error `message` and exit
      # `code`.
      #
      # @param [String] message
      # @param [Integer] code.
      def die message=nil, code=126
        self.class.die(message, code)
      end

    end
  end
end
