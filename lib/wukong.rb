require 'configliere'
require 'vayacondios-client'
require 'multi_json'
require 'eventmachine'
require 'log4r'

require 'hanuman'

require 'wukong/logger' 
require 'wukong/processor'
require 'wukong/dataflow'
require 'wukong/widgets'
require 'wukong/plugin'
require 'wukong/driver'
require 'wukong/runner'
require 'wukong/local'

# The Wukong module will contain all code for Wukong's core (like
# Processors and Dataflows) as well as all plugins.
#
# Plugins are expected to own their own namespace within Wukong,
# e.g. - Wukong::Hadoop, Wukong::Storm, &c.
module Wukong
  extend Hanuman::Shortcuts

  # A common error class intended to be raised by code within Wukong
  # or its plugins.
  class Error < StandardError
    def initialize msg_or_error
      if msg_or_error.respond_to?(:message) && msg_or_error.respond_to?(:backtrace)
        super([msg_or_error.message, msg_or_error.backtrace].compact.join("\n"))
      else
        super(msg_or_error)
      end
    end
  end
  
  add_shortcut_method_for(:processor, ProcessorBuilder)
  add_shortcut_method_for(:dataflow,  DataflowBuilder)

end

# Alias module name for shorter namespaces
Wu = Wukong
