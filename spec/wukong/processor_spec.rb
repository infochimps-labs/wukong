require 'spec_helper'

describe Wukong::Processor do

  subject { Wukong::Processor.new }
  
  it{ should respond_to(:setup)    }
  it{ should respond_to(:process)  }
  it{ should respond_to(:finalize) }
  it{ should respond_to(:stop)     }
  it{ should respond_to(:notify)   }
end
  
