require 'configliere'
require 'gorillib/logger/log'
require 'vayacondios-client'
require 'multi_json'

require 'hanuman'

require 'wukong/processor'
require 'wukong/driver'
require 'wukong/widget/processors'
require 'wukong/emitter'
require 'wukong/widget/source'
require 'wukong/widget/sink'
require 'wukong/widget/reducer'
require 'wukong/widget/serializers'
require 'wukong/dataflow'
require 'wukong/configuration'

module Wukong
  extend Hanuman::Shortcuts

  Error = Class.new(StandardError)
  
  add_shortcut_method_for(:processor, ProcessorBuilder)
  add_shortcut_method_for(:dataflow,  DataflowBuilder)

end
