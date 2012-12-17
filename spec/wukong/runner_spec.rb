require 'spec_helper'

describe Wukong::Runner do

  context "with a specific runner class" do

    let(:runner) do
      Class.new(Wukong::Runner) do |c|
        c.class_eval do
          attr_accessor :fails
          def evaluate_args
            self.fails = true if settings[:fails]
          end
          def run_driver
            raise Wukong::Error.new("should get captured") if self.fails
          end
        end
      end
    end
    subject { runner.new }

    it "will call the 'load_code_from_args' method" do
      subject.should_receive(:args_to_load)
      subject.run
    end

    it "will call the 'evaulate_args' method" do
      subject.should_receive(:evaluate_args)
      subject.run
    end

    it "will call the 'run_driver' method" do
      subject.should_receive(:run_driver)
      subject.run
    end

    it "captures errors from the runner subclasses" do
      settings = Configliere::Param.new
      settings.merge!(:fails => true)
      r = runner.new(settings)
      r.should_receive(:evaluate_args).and_raise(Wukong::Error, "hi there")
      r.log.should_receive(:error).with("hi there")
      lambda { r.run }.should raise_error(SystemExit)
    end
    
  end
end
