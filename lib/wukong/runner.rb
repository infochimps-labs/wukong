require_relative("runner/code_loader")
require_relative("runner/deploy_pack_loader")
require_relative("runner/lifecycle")

module Wukong

  # A base class which handles
  #
  # * requiring any necessary code like deploy packs or code from command-line arguments
  # * having all plugins configure settings as necessary
  # * resolving settings
  # * having all plugins boot from now resolved settings
  # * parsing command-line arguments
  # * instantiating and handing over control to a driver which runs the actual code
  class Runner
    
    include Logging
    include CodeLoader
    include DeployPackLoader
    include Lifecycle

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
    
    # Instantiates a new Runner and take it thrugh its lifecycle.
    #
    # Will rescue any Wukong::Error with a logged error message and
    # exit.
    def self.run(settings=Configliere::Param.new)
      begin
        new(settings).perform_lifecycle
      rescue Wukong::Error => e
        die(e.message, 127)
      end
    end

    # Set or get the name of the command-line program this Runner
    # implements.
    #
    # @param [String] name the program name to set
    # @return [String] the program name
    def self.program name=nil
      @program_name = name if name
      @program_name
    end

    # The name of the currently running program.
    #
    # @return [String]
    def program_name
      self.class.program || File.basename($0)
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

    # Convenience method for setting the usage message of a Runner.
    #
    # @param [String, nil] msg set the usage message
    # @return [String] the usage message
    def self.usage msg=nil
      return @usage unless msg
      @usage = msg
    end
    
    # Convenience method for setting the description message of a Runner.
    #
    # @param [String, nil] msg set the description message
    # @return [String] the description message
    def self.description msg=nil
      return @description unless msg
      @description = msg
    end

    # Kill this process with the given error `message` and exit
    # `code`.
    #
    # @param [String] message
    # @param [Integer] code.
    def self.die(message=nil, code=127)
      log.error(message) if message
      exit(code)
    end

    # Return the usage message for this runner.
    #
    # @return [String] the usage message
    def usage
      ["usage: #{program_name} [ --param=val | --param | -p val | -p ]", self.class.usage].compact.join(' ')
    end

    # Return the description text for this runner.
    #
    # @return [String] the description text
    def description
      self.class.description
    end

    # Is there a processor registered by the given `name`?
    #
    # @param [String] name
    # @return [true, false]
    def registered? name
      return false unless name
      Wukong.registry.registered?(name.to_sym)
    end

  end    
end
