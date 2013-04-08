require 'spec_helper'

describe Wukong::Processor do

  subject { Wukong::Processor.new }  

  describe "has an interface" do
    it{ should respond_to(:setup)    }
    it{ should respond_to(:process)  }
    it{ should respond_to(:finalize) }
    it{ should respond_to(:stop)     }
  end

  describe "default process method" do
    it "yields the original input record by default on process" do
      expect { |b| subject.process(1, &b) }.to yield_with_args(1)
    end
  end
  
end
  
