require_relative("deploy_pack_loader")
module Wukong

  # A base class which handles
  #
  # * requiring any necessary code like deploy packs or code from command-line arguments
  # * having all plugins configure settings as necessary
  # * resolving settings
  # * having all plugins boot from now resolved settings
  # * parsing command-line arguments
  # * instantiating and handing over control to a driver which runs the actual code
  #
  # If you subclass this class, you'll likely want to implement the
  #
  # * `args_to_load` method to load any additional code or libraries given on the command-line
  # * `evaluate_args` method to evaulate (resolved) arguments to decide what to do
  # * `run_driver` method to instantiate the appropriate driver and hand over control
  class Runner
    include Logging
    include DeployPackLoader

    # The settings object that will be configured and booted from.
    # All plugins will configure this object.
    attr_accessor :settings

    # Create a new Runner with the given +settings+.
    #
    # Uses an empty Configliere::Param object if no +settings+ are
    # given.
    #
    # @param [Configliere::Param] settings
    def initialize settings=Configliere::Param.new
      self.settings = settings
    end

    # The name of the currently running program.
    #
    # @return [String]
    def program_name
      File.basename($0)
    end

    # The parsed command-line arguments.
    #
    # Will raise an error if +boot+ hasn't been called yet.
    #
    # @return [Array<String>]
    def args
      settings.rest
    end

    # The root directory we should consider ourselves to be running
    # in.
    #
    # Defaults to the root directory of a deploy pack if we're running
    # inside one, else just returns `Dir.pwd`.
    #
    # @return [String]
    def root
      in_deploy_pack? ? deploy_pack_dir : Dir.pwd
    end

    # Return the usage message for this runner.
    #
    # @return [String] the usage message
    def usage
      ["usage: #{program_name} [ --param=val | --param | -p val | -p ]", self.class.usage].compact.join(' ')
    end

    # Convenience method for setting the usage message of a Runner.
    #
    # @param [String, nil] msg set the usage message
    # @return [String] the usage message
    def self.usage msg=nil
      return @usage unless msg
      @usage = msg
    end

    # Return the description text for this runner.
    #
    # @return [String] the description text
    def description
      self.class.description
    end

    # Convenience method for setting the description message of a Runner.
    #
    # @param [String, nil] msg set the description message
    # @return [String] the description message
    def self.description msg=nil
      return @description unless msg
      @description = msg
    end
    
    # Load any additional code that we found out about on the
    # command-line.
    #
    # You'll want to override this method in your own Runner class.
    #
    # @return [Array<String>] paths to load culled from the ARGV.
    def args_to_load
      ruby_file_args || []
    end

    # Returns all pre-resolved arguments which are Ruby files.
    #
    # @return [Array<String>]
    def ruby_file_args
      ARGV.find_all { |arg| arg.to_s =~ /\.rb$/ && arg.to_s !~ /^--/ }
    end
    
    # Evaluate all arguments from the command-line.
    #
    # You'll want to override this method in your own Runner class.
    def evaluate_args
    end

    # Run this runner.
    #
    # You'll want to override this method in your own Runner class.
    def run
    end

    # Run this runner, booting up, evaluating all arguments, and
    # running the driver.
    #
    # Will rescue any Wukong::Error with a logged error message and
    # exit.
    def self.run(settings=Configliere::Param.new)
      runner = new(settings)
      begin
        runner.boot
        runner.run
      rescue Wukong::Error => e
        log.error(e.message)
        exit(127)
      end
    end

    # Boots the runner by loading all code, configuring all settings,
    # resolving the settings, and booting all plugins as necessary,
    # and evaluating command-line arguments.
    def boot
      load_all_code
      configure_settings
      settings.resolve!
      Wukong.boot_plugins(settings, root)
      evaluate_args
    end
    
    private
    
    # Loads all code, whether from a deploy pack or additionally
    # passed on the command line.
    def load_all_code
      load_environment_code
      (args_to_load || []).each do |path|
        load_ruby_file(path)
      end
    end

    # Loads a single Ruby file, capturing LoadError and SyntaxError
    # and raising Wukong::Error instead (so it can be easily captured
    # by the Runner).
    #
    # @param [String] path
    # @raise [Wukong::Error] if there is an error
    def load_ruby_file path
      return unless path
      begin
        load path
      rescue LoadError, SyntaxError => e
        raise Error.new(e.message)
      end
    end

    # Configure the settings object, adding this runner's usage and
    # description, but also settings from all plugins.
    def configure_settings
      settings.use(:commandline)
      settings.description = self.description if self.description
      u = self.usage
      settings.define_singleton_method(:usage){ u } if u
      Wukong.configure_plugins(settings, program_name)
    end
    
  end    
end
