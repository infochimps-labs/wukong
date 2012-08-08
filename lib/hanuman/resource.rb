module Hanuman
  class Resource < Stage
    include Hanuman::IsOwnInputSlot
    include Hanuman::IsOwnOutputSlot
    field :schema, Whatever, :default => ->{ Whatever }
  end
end
