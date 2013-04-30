require 'spec_helper'

describe Wukong::DriverMethods do
  
  describe "#construct_dataflow" do
    
    context "given a label registered to a processor" do
      let(:driver)   { Wukong::SpecHelpers::UnitTestDriver.new(:regexp, match: /hi/) }
      
      context "constructs an anonymous dataflow" do
        let(:dataflow) { driver.dataflow }
        subject        { dataflow }
        
        it          { should_not be_nil   }
        its(:label) { should     be_nil   }
        its(:links) { should     be_empty }
        
        context "with a single stage" do
          let(:stage) { dataflow.stages.values.first }
          subject     { stage }

          it          { should_not be_nil }
          its(:label) { should == :regexp }
          its(:match) { should == /hi/    }
        end
      end
    end

    context "given a serialization argument" do
      context "that does not match a registered serializer" do
        it "raises an error" do
          expect { Wukong::SpecHelpers::UnitTestDriver.new(:regexp, match: /hi/, to: 'fake') }.to raise_error(Wukong::Error)
        end
      end
      context "that matches a registered serializer" do
        let(:driver)   { Wukong::SpecHelpers::UnitTestDriver.new(:regexp, match: /hi/, to: 'json') }
        let(:dataflow) { driver.dataflow }
        it "appends the serializer to each of the leaves" do
          dataflow.leaves.size.should == 1
          dataflow.leaves.map(&:label).should_not include(:regexp)
        end
      end
    end
    
    context "given a deserialization argument" do
      let(:driver)   { Wukong::SpecHelpers::UnitTestDriver.new(:regexp, match: /hi/, from: 'json') }
      let(:dataflow) { driver.dataflow }

      context "adds a deserializer" do
        subject { dataflow.stages[:from_json] }
        it      { should_not be_nil   }
        it "which is the root of the dataflow" do
          dataflow.root.should == subject
        end
        it "which is linked to the original root" do
          dataflow.ancestors(dataflow.stages[:regexp]).should include(subject)
        end
      end
    end

    context "given a recordization argument" do
      let(:driver)   { Wukong::SpecHelpers::UnitTestDriver.new(:regexp, match: /hi/, as: Time) }
      let(:dataflow) { driver.dataflow }
      
      context "adds a recordizer" do
        subject { dataflow.stages[:recordize] }
        it      { should_not be_nil   }
        it "which is the root of the dataflow" do
          dataflow.root.should == subject
        end
        it "which is linked to the original root" do
          dataflow.ancestors(dataflow.stages[:regexp]).should include(subject)
        end
      end
    end

    context "given deserialization and recordization arguments" do
      let(:driver)       { Wukong::SpecHelpers::UnitTestDriver.new(:regexp, match: /hi/, from: 'json', as: Time) }
      let(:dataflow)     { driver.dataflow }
      let(:recordizer)   { dataflow.stages[:recordize] }
      let(:deserializer) { dataflow.stages[:from_json] }

      context "adds a deserializer" do
        subject { deserializer      }
        it      { should_not be_nil }
        it "which is the root of the dataflow" do
          dataflow.root.should == subject
        end
        it "which is linked to the recordizer" do
          dataflow.ancestors(dataflow.stages[:recordizer]).should include(subject)
        end
      end
      
      context "adds a recordizer" do
        subject { recordizer        }
        it      { should_not be_nil }
        it "which is linked to the original root" do
          dataflow.ancestors(dataflow.stages[:regexp]).should include(subject)
        end
      end
      
    end
  end

  describe "#setup_dataflow" do
    let(:driver)   { Wukong::SpecHelpers::UnitTestDriver.new(:regexp, match: /hi/) }
    
    it "calls the driver's #setup method" do
      driver.should_receive(:setup)
      driver.setup_dataflow
    end

    it "calls setup on each stage of the dataflow" do
      driver.dataflow.each_stage do |stage|
        stage.should_receive(:setup)
      end
      driver.setup_dataflow
    end
  end

  describe "#finalize_dataflow" do
    let(:driver)   { Wukong::SpecHelpers::UnitTestDriver.new(:regexp, match: /hi/) }
    it "calls the driver's #finalize method" do
      driver.should_receive(:finalize)
      driver.finalize_dataflow
    end

    it "calls finalize on each stage of the dataflow" do
      driver.dataflow.each_stage do |stage|
        stage.should_receive(:finalize)
      end
      driver.finalize_dataflow
    end
  end

  describe "#finalize_and_stop_dataflow" do
    let(:driver)   { Wukong::SpecHelpers::UnitTestDriver.new(:regexp, match: /hi/) }
    it "calls the driver's #finalize and #stop methods" do
      driver.should_receive(:finalize)
      driver.should_receive(:stop)
      driver.finalize_and_stop_dataflow
    end

    it "calls finalize and stop on each stage of the dataflow" do
      driver.dataflow.each_stage do |stage|
        stage.should_receive(:finalize)
        stage.should_receive(:stop)
      end
      driver.finalize_and_stop_dataflow
    end
    
  end
  
end
