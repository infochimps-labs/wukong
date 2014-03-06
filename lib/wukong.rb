require 'configliere'
require 'multi_json'
require 'eventmachine'
require 'log4r'

require_relative 'hanuman'
require_relative 'wukong/logger' 
require_relative 'wukong/processor'
require_relative 'wukong/dataflow'
require_relative 'wukong/plugin'
require_relative 'wukong/driver'
require_relative 'wukong/runner'


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

  def self.doc_helpers_path
    File.expand_path('../wukong/doc_helpers.rb', __FILE__)
  end
  
end

# Alias module name for shorter namespaces
Wu = Wukong

require_relative 'wukong/widgets'
require_relative 'wukong/local'

module Wukong

  # Built-in Wukong processors and dataflows.
  BUILTINS = Set.new(Wukong.registry.show.keys)
end
