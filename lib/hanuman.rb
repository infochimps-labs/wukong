
require 'gorillib/builder'

require 'hanuman/stage'              # base object for building blocks
require 'hanuman/action'             # represents a transformation of resources
require 'hanuman/resource'           # represents a resource
require 'hanuman/graph'              # coordinates wukong stages

require 'hanuman/slot'               # coordinate connections

module Hanuman
  class Stage
    include Hanuman::InputSlot
    include Hanuman::OutputSlot
  end
end
