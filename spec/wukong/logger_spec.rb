require 'spec_helper'

describe Wukong::Logging do

  let(:loggable) { Class.new.class_eval { include Wukong::Logging } }
  let(:model)    { Class.new.class_eval { include Gorillib::Model } }
  
  describe "a class including Wukong::Logging" do
    subject { loggable }

    it { should respond_to(:log) }

    describe "has instances that" do
      let(:loggable_instance) { loggable.new      }
      subject                 { loggable_instance }
      
      it   { should respond_to(:log)   }
      describe "have an instance method #log that" do
        let(:log) { loggable_instance.log }
        subject   { log                   }

        it { should respond_to(:debug) }
        it { should respond_to(:info)  }
        it { should respond_to(:warn)  }
      end
    end

    describe "has subclasses" do
      let(:child)  { Class.new(loggable)    }
      
      describe "with instances that" do
        subject { child.new }
        
        it      { should respond_to(:log)   }
      end
    end
  end

  describe "a class including Gorillib::Model and then Wukong::Logging" do
    let(:loggable_model) { model.class_eval { include Wukong::Logging } }
    subject              { loggable_model                               }
    
    describe "has fields that" do
      subject { loggable_model.fields }
      it      { should include(:log) }
    end
  end
end

