require 'spec_helper'

describe :logger do
  it_behaves_like "a processor", :named => :logger

  it "logs each event at the 'info' level by default" do
    log = double("logger")
    log.should_receive(:info).with('hi there')
    log.should_receive(:info).with('buddy')
    processor(:logger) do |proc|
      proc.stub(:log).and_return(log)
    end.given('hi there', 'buddy').should emit(0).records
  end

  it "logs each event at the a desired level set with an argument" do
    log = double("logger")
    log.should_receive(:debug).with('hi there')
    log.should_receive(:debug).with('buddy')
    processor(:logger, level: :debug) do |proc|
      proc.stub(:log).and_return(log)
    end.given('hi there', 'buddy').should emit(0).records
  end
end
