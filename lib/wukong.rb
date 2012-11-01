require 'configliere'

require 'gorillib/logger/log'

require 'hanuman'

require 'wukong/processor'
require 'wukong/driver'
require 'wukong/widget/processors'
require 'wukong/emitter'
require 'wukong/widget/source'
require 'wukong/widget/sink'
require 'wukong/dataflow'

module Wukong
  extend Hanuman::Shortcuts
  
  add_shortcut_method_for(:processor, ProcessorBuilder)
  add_shortcut_method_for(:dataflow,  DataflowBuilder)

end
