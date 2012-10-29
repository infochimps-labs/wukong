module Hanuman
  class Product < Stage

    magic      :name,    Symbol, position: 0, doc: 'name of this stage'
    magic      :schema,  Whatever, default: ->{ Whatever }, doc: 'schema for type of data contained in this product'

    include Hanuman::InputSlotted
    include Hanuman::OutputSlotted

  end
end
