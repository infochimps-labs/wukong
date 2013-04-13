require 'gorillib/some'
require 'gorillib/model'

require 'hanuman/registry'
require 'hanuman/link'
require 'hanuman/stage'              
require 'hanuman/graph'
require 'hanuman/tree'

module Hanuman
  module Shortcuts
    
    def builder_shortcut(builder_type, label, *args, &blk)
      if GlobalRegistry.registered?(label)
        builder = GlobalRegistry.retrieve(label)
      else
        builder = builder_type.receive(label: label)
      end
      GlobalRegistry.decorate_with_registry(builder) if builder.is_a?(GraphBuilder)
      builder.define(*args, &blk)
    end
    
    def add_shortcut_method_for(method_name, builder_type)
      self.define_singleton_method(method_name){ |label, *args, &blk| builder_shortcut(builder_type, label, *args, &blk) }
    end

    def registry() Hanuman::GlobalRegistry ; end    
    
  end

  extend Hanuman::Shortcuts
  
  add_shortcut_method_for(:stage, StageBuilder)
  add_shortcut_method_for(:graph, GraphBuilder)

end
