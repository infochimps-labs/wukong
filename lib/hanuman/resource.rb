module Hanuman
  class Resource < Stage

    magic      :name,    Symbol,            :position => 0, :doc => 'name of this stage'
    magic      :schema,  Gorillib::Factory, :default => ->{ Whatever }

  end
end
