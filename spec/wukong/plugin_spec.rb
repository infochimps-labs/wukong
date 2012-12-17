require 'spec_helper'

describe Wukong::Plugin do

  before do
    @original_plugins = Wukong::PLUGINS.dup
    Wukong::PLUGINS.replace([])
  end

  after do
    Wukong::PLUGINS.replace(@original_plugins)
  end

  subject do
    Class.new.tap do |c|
      c.class_eval do
        include Wukong::Plugin
        def self.configure settings, name
        end
        def self.boot settings, root
        end
      end
    end
  end

  let(:settings)     { Configliere::Param.new }
  let(:program_name) { 'wu-spec-program-name' }
  let(:program_dir)  { '/root/program/dir'    }

  context "defining a new plugin" do
    it_behaves_like 'a plugin'
  end
  
  it "calls the 'configure' method on each plugin" do
    subject.should_receive(:configure).with(settings, program_name)
    Wukong.configure_plugins(settings, program_name)
  end
  
  it "calls the 'boot' method on each plugin" do
    subject.should_receive(:boot).with(settings, program_dir)
    Wukong.boot_plugins(settings, program_dir)
  end
  
end
