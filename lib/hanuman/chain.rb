module Hanuman
  class Chain < Graph
    include Hanuman::InputSlotted
    include Hanuman::OutputSlotted
  end
end
