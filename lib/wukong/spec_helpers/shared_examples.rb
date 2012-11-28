shared_examples_for 'a processor' do |options={}|
  name = options[:named]
  if name
    it "is registered with the name '#{name}'" do
      Wukong.registry.retrieve(name.to_sym).should_not be_nil
    end
    it{ create_processor(name).should respond_to(:setup)    }
    it{ create_processor(name).should respond_to(:process)  }
    it{ create_processor(name).should respond_to(:finalize) }
    it{ create_processor(name).should respond_to(:stop)     }
    it{ create_processor(name).should respond_to(:notify)   }
  else
    warn "Must supply a name for a processor you want to test"
  end
end
