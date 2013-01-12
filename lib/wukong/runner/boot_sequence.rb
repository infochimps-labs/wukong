require_relative('help_message')
module Wukong
  class Runner

    # The boot sequence of a runner consists of the following phases,
    # each corresponding to a method provided by this module.
    #
    # * #load -- loads all application code
    # * #configure -- configures settings from core Wukong, any loaded plugins, and any application code
    # * #resolve -- resolves settings
    # * #setup -- boots core Wukong and all loaded plugins
    # * #validate -- validates command-line args
    # * #run -- starts the runner running
    #
    # Each method can be separately overriden, allowing for a lot of
    # customizability for different kinds of runners.
    module BootSequence

      include HelpMessage
      
      # Boot this Runner, calling in order:
      #
      # * #load
      # * #configure
      # * #resolve
      # * #setup
      # * #validate
      # * #run or #die
      #
      # If `override_settings` is passed then merge it over the
      # Runner's usual settings (this is useful for unit tests where
      # settings are injected in ways different from the usual
      # workflow).
      #
      # @param [Configliere::Param] override_settings
      def boot!(override_settings=nil)
        load
        configure
        resolve
        setup
        settings.merge!(override_settings) if override_settings
        
        case
        when help_given? then dump_help_and_exit!
        when validate    then run
        else
          die("Invalid arguments")
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
          strip_help_param!
          settings.resolve!
          true
        rescue RuntimeError, SystemExit => e
          raise Error.new(e)
        end
      end
      
      # Performs any setup code necessary before run.
      #
      # Boots all plugins by default.  If you override this code, make
      # sure to either call `super` or boot plugins yourself.
      def setup
        Wukong.boot_plugins(settings, root)
      end

      # Validates the command-line args.  Raise a Wukong::Error in
      # this method to terminate execution with a specific or custom
      # error.
      #
      # Return false-like to terminate with a generic argument error.
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
      # @param [Integer] code
      def die message=nil, code=126
        self.class.die(message, code)
      end

    end
  end
end
