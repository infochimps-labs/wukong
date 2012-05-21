module Hanuman
  class Resource < Stage
    has_input
    has_output
    field :schema, Gorillib::Factory, :default => ->{ Whatever }
  end
end
