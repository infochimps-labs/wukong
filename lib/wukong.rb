require 'configliere'
require 'gorillib/logger/log'
require 'vayacondios-client'
require 'multi_json'

require 'hanuman'

require 'wukong/processor'
require 'wukong/driver'

require 'wukong/emitter'
require 'wukong/dataflow'
require 'wukong/configuration'
require 'wukong/widgets'

# The Wukong module will contain all code for Wukong's core (like
# Processors and Dataflows) as well as all plugins.
#
# Plugins are expected to own their own namespace within Wukong,
# e.g. - Wukong::Hadoop, Wukong::Storm, &c.
module Wukong
  extend Hanuman::Shortcuts

  # A common error class intended to be raised by code within Wukong
  # or its plugins.
  Error = Class.new(StandardError)
  
  add_shortcut_method_for(:processor, ProcessorBuilder)
  add_shortcut_method_for(:dataflow,  DataflowBuilder)

end
