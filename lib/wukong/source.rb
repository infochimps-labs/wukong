module Wukong

  # Provides a runner for periodically triggering a dataflow or
  # processor.
  module Source
    include Plugin

    # Configures the given +settings+ object with all settings
    # specific to Wukong::Source for the given program +name+.
    #
    # @param [Configliere::Param] settings the settings to configure
    # @param [String] program the name of the currently executing program
    def self.configure settings, program
      case program
      when 'wu-source'
        settings.define :per_sec,    description: "Number of events produced per second", type: Float
        settings.define :period,     description: "Number of seconds between events (overrides --per_sec)", type: Float
        settings.define :batch_size, description: "Trigger a finalize across the dataflow each time this many records are processed", type: Integer
      end
    end

    # Boots Wukong::Source using the given +settings+ at the given
    # +root.
    #
    # @param [Configliere::Param] settings the settings to use to boot
    # @param [String] root the root directory to boot in
    def self.boot(settings, root)
    end
    
  end
end

require_relative('source/source_runner')
