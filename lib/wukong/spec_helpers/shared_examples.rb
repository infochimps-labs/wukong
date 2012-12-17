shared_examples_for 'a processor' do |options = {}|
  let(:processor_name){ options[:named] || self.class.top_level_description }
  subject             { create_processor(processor_name, on_error: :skip)   }

  it 'is registered' do
    Wukong.registry.retrieve(processor_name.to_sym).should_not be_nil
  end
  
  it{ should respond_to(:setup)    }
  it{ should respond_to(:process)  }
  it{ should respond_to(:finalize) }
  it{ should respond_to(:stop)     }
  it{ should respond_to(:notify)   }
end

shared_examples_for 'a plugin' do |options = {}|
  it "has a 'configure' method " do
    should respond_to(:configure)
  end
  it "has a 'boot' method" do
    should respond_to(:boot)
  end
end
