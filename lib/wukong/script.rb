require 'wukong'

#
# Runner settings
#

Settings.define :mode, :type => Symbol, :default => :mapper

module Wukong
  # adds ability to execute
  extend Wukong::Mixin::FromFile

  #
  # sources a script file,
  #
  class Script
    attr_reader :settings     # configliere hash of options
    attr_reader :script_file  # File to execute

    def initialize(script_file, settings)
      @script_file = script_file
      @settings = settings
    end

    # Execute the script file in the context of the Wukong module
    def run
      Log.debug( "Running #{script_file} with settings #{settings}")
      script_file = self.script_file
      mode        = settings.mode
      Wukong.module_eval do
        from_file(script_file)
        flow(mode).run
      end
    end
  end
end
