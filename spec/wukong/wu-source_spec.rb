require 'spec_helper'

describe 'wu-source' do

  let(:input) { %w[1 2 3] }
  
  context "without any arguments" do
    subject { wu_source() }
    it {should exit_with(:non_zero) }
    it "displays help on STDERR" do
      should have_stderr(/provide a processor.*to run/)
    end
  end

  # FIXME -- it's hard to write an integration test for wu-source
  # because it doesn't self-terminate under any conditions when run
  # successfully.
  #
  # Options:
  #
  #   1) Add a --max (or similar) flag to wu-source allowing it to
  #      exit after some number of records which could then be checked
  #      by an integration test.
  #
  #   2) Launch it in a subprocess and wait a little while (how long?)
  #   and ensure that it's produced a bunch of output in the meantime.
  #   If the `per_sec` option is high, we shouldn't have to wait very
  #   long to see a whole bunch of output records.  This is tricky b/c
  #   what if the system is under load and we don't wait long enough
  #   for the wu-source subprocess to boot up and start emitting?
  
end
