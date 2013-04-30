require 'spec_helper'

describe Wukong::Local::StdioDriver do
  before { EM.stub!(:stop) }
  
  let(:driver) { Wukong::Local::StdioDriver.new(:bogus_event_machine_inserted_arg, :identity, {}) }

  it "attaches itself as an EventMachine handler for $stdin, providing the given label and settings" do
    EM.should_receive(:attach).with($stdin, Wukong::Local::StdioDriver, :foo, {})
    Wukong::Local::StdioDriver.start(:foo, {})
  end

  describe "setting up a dataflow" do
    context "#post_init hook from EventMachine" do
      after { driver.post_init }
      
      it "sets signal traps for INT and TERM" do
        Signal.should_receive(:trap).with('INT').at_least(:once)
        Signal.should_receive(:trap).with('TERM').at_least(:once)
      end
      
      it "calls the #setup_dataflow method" do
        driver.should_receive(:setup_dataflow).at_least(:once)
      end
      
      it "syncs $stdout" do
        $stdout.should_receive(:sync).at_least(:once)
      end
      
    end
  end

  describe "driving a dataflow" do
    context "#receive_line hook from EventMachine" do
      let(:line) { "hello" }
      
      after  { driver.receive_line(line) }
      it "passes the line to the #send_through_dataflow method" do
        driver.should_receive(:send_through_dataflow).with(line)
      end
      
      context "upon an error within the dataflow" do
        let(:message) { "whoops" }
        
        before do
          driver.should_receive(:send_through_dataflow).with(line) do
            raise Wukong::Error.new(message)
          end
          driver.log.stub!(:error)
        end
        
        
        it "logs an error message" do
          driver.log.should_receive(:error).with(kind_of(String))
        end
        it "stops the EventMachine reactor" do
          EM.should_receive(:stop)
        end
      end
    end
  end

  describe "shutting down a dataflow" do
    context "#unbind hook from EventMachine" do
      after { driver.unbind }
      
      it "calls the #finalize_and_stop_dataflow method" do
        driver.should_receive(:finalize_and_stop_dataflow)
      end
      
      it "stops the EventMachine reactor" do
        EM.should_receive(:stop)
      end
      
    end
  end
end
