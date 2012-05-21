require 'spec_helper'
require 'hanuman'

describe :stages, :slot_specs => true, :helpers => true do

  describe Hanuman::Stage do
    it{ should respond_to(:setup)  }
    it{ should respond_to(:stop)   }
    it{ should respond_to(:notify) }
    it{ should respond_to(:report) }
  end
end
