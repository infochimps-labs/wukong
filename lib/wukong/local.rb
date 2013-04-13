module Wukong

  # Provides methods for supporting the running of Wukong processors
  # and dataflows entirely locally, without any frameworks like Hadoop
  # or Storm.
  #
  # This module is actually a plugin for Wukong.
  module Local
    include Plugin

    # Configures the given +settings+ object with all settings
    # specific to Wukong::Local for the given program +name+.
    #
    # @param [Configliere::Param] settings the settings to configure
    # @param [String] program the name of the currently executing program
    def self.configure settings, program
      case program
      when 'wu-local'
        settings.define :run,  description: "Name of the processor or dataflow to use. Defaults to basename of first argument", flag: 'r'
        
        settings.define :from, description: "Parse input from given data format (json, tsv, &c.) before processing"
        settings.define :to,   description: "Convert input to given data format (json, tsv, &c.) before emitting"
        settings.define :as,   description: "Call Class.receive on each input (will run after --from)", type: Class
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

require_relative('local/runner')
