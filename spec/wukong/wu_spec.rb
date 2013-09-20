require 'spec_helper'

describe 'wu' do

  let(:input) { %w[1 2 3] }
  
  context "without any arguments" do
    subject { wu() }
    it {should exit_with(:non_zero) }
    it "displays help on STDERR" do
      should have_stderr(/provide a Wukong command to run/)
    end
  end
end
