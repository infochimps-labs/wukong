require 'configliere'
require 'gorillib/logger/log'
require 'vayacondios-client'
require 'multi_json'
require 'eventmachine'

require 'hanuman'

require 'wukong/processor'
require 'wukong/driver'
require 'wukong/server'
require 'wukong/emitter'
require 'wukong/dataflow'
require 'wukong/configuration'
require 'wukong/widgets'

module Wukong
  extend Hanuman::Shortcuts

  Error = Class.new(StandardError)
  
  add_shortcut_method_for(:processor, ProcessorBuilder)
  add_shortcut_method_for(:dataflow,  DataflowBuilder)

end
