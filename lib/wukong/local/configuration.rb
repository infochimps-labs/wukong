module Wukong
  module Local

    # Configures the given +settings+ object with all settings
    # specific to Wukong::Local for the given program +name+.
    #
    # @param [Configliere::Param] settings the settings to configure
    # @param [String] program the name of the currently executing program
    def self.configure settings, program
      case program
      when 'wu-local'
        settings.define :run,        description: "Name of the processor or dataflow to use. Defaults to basename of the given path.", flag: 'r'
        settings.define :tcp_server, description: "Run locally as a server using provided TCP port", default: false,                   flag: 't'
      end
    end

    # Boots Wukong::Local using the given +settings+ at the given
    # +root.
    #
    # @param [Configliere::Param] settings the settings to use to boot
    # @param [String] root the root directory to boot in
    def self.boot(settings, root)
    end
    
  end
end
