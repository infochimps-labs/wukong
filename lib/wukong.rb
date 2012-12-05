require 'configliere'
require 'vayacondios-client'
require 'multi_json'
require 'eventmachine'
require 'log4r'

require 'hanuman'

require 'wukong/logger' 
require 'wukong/processor'
require 'wukong/dataflow'
require 'wukong/configuration'
require 'wukong/widgets'
require 'wukong/driver'
require 'wukong/server'
# require 'wukong/runner'

module Wukong
  extend Hanuman::Shortcuts

  Error = Class.new(StandardError)
  
  add_shortcut_method_for(:processor, ProcessorBuilder)
  add_shortcut_method_for(:dataflow,  DataflowBuilder)

end

# Alias module name for shorter namespaces
Wu = Wukong
