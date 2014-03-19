require 'spec_helper'

describe Wukong::Local::LocalRunner do
  before { EM.stub(:run) }

  describe "choosing a processor name" do

    it "raises an error without any arguments" do
      expect { local_runner() }.to raise_error(Wukong::Error, /must provide.*processor.*run.*argument/i)
    end
    
    it "raises an error when passed the name of a processor that isn't registered" do
      expect { local_runner('some_proc_that_dont_exit') }.to raise_error(Wukong::Error, /no such processor.*some_proc.*/i)
    end
    
    it "accepts an explicit --run argument" do
      local_runner('--run=identity').processor.should == 'identity'
    end
    
    it "accepts a registered processor name from the first argument" do
      local_runner('identity').processor.should == 'identity'
    end
    
    it "accepts a registerd processor name from the the basename of the first file argument" do
      local_runner(examples_dir('string_reverser.rb')).processor.should == 'string_reverser'
    end
  end
  
end
