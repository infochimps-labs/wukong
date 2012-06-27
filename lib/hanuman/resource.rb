module Hanuman
  class Resource < Stage
    include Hanuman::IsOwnInputSlot
    include Hanuman::IsOwnOutputSlot
    magic :schema, Gorillib::Factory, :default => ->{ Whatever }
  end
end
