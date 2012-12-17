module Wukong

  # An array of loaded Plugins.
  PLUGINS = []

  # Asks each loaded plugin to configure the given +settings+ for the
  # given +program_name+.
  #
  # @param [Configliere::Param] settings the settings to be configured by each plugin
  # @param [String] program_name the name of the currently executing program
  def self.configure_plugins(settings, program_name)
    PLUGINS.each do |plugin|
      plugin.configure(settings, program_name)
    end
  end

  # Asks each loaded plugin to boot itself from the given +settings+
  # in the given +root+ directory.
  #
  # @param [Configliere::Param] settings the settings for each plugin to boot from
  # @param [String] root the root directory the plugins are booting in
  def self.boot_plugins(settings, root)
    PLUGINS.each do |plugin|
      plugin.boot(settings, root)
    end
  end

  # Include this module in your own class or module to have it
  # register itself as a Wukong plugin.
  #
  # Your class or module must define the following methods:
  #
  # * `configure` called with a (pre-resolved) Configliere::Param argument and the basename of the running program
  # * `boot` called with a (resolved) Configliere::Param argument and the current working directory of the running program, reacts to any settings as necessary
  #
  # Subclasses of Wukong::Runner will automatically load and boot each
  # plugin.
  module Plugin
    # :nodoc:
    def self.included mod
      PLUGINS << mod unless PLUGINS.include?(mod)
    end
  end
  
end

    
    
