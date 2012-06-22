require 'gorillib'
require 'gorillib/metaprogramming/class_attribute'
require 'gorillib/builder'

require 'hanuman/stage'              # base object for building blocks
require 'hanuman/slot'               # ports for inputs and outputs of stages
require 'hanuman/slottable'          # modules that equip stages with input and output slots
require 'hanuman/action'             # represents a transformation of resources
require 'hanuman/resource'           # represents a resource
require 'hanuman/graph'              # coordinates wukong stages
