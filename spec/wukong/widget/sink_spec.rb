require 'spec_helper'

describe :sinks, :helpers => true do

  describe Wukong::Sink::Stdout do
    it 'dumps records to $stdout'
    # $stdout.should_receive(:puts).with(mock_record)
    # subject.call(mock_record)
  end

  describe Wukong::Sink::Stderr do
    it 'dumps records to $stderr'
    # $stderr.should_receive(:puts).with(mock_record)
    # subject.call(mock_record)
  end
end
