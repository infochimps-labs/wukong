require 'spec_helper'

describe Wukong::DeployPackLoader do

  let(:runner) do
    Class.new.tap do |c|
      c.class_eval do
        include Wukong::DeployPackLoader
      end
    end
  end

  context "in an arbitrary directory" do
    let(:dir) { examples_dir('empty') }
    before    { FileUtils.cd(dir)     }
    subject   { runner.new            }
    its(:deploy_pack_dir)  { should == '/'                      }
    its(:environment_file) { should == '/config/environment.rb' }
    its(:in_deploy_pack?)  { should be_false                    }
  end

  context "when BUNDLE_GEMFILE points at a regular Ruby project" do
    let(:dir)             { examples_dir('empty')       }
    let(:deploy_pack_dir) { examples_dir('ruby_project') }
    before do
      FileUtils.cd(dir)
      ENV.stub!(:[]).with("BUNDLE_GEMFILE").and_return(deploy_pack_dir.join("Gemfile"))
    end
    subject   { runner.new }
    its(:deploy_pack_dir)  { should == '/'                      }
    its(:environment_file) { should == '/config/environment.rb' }
    its(:in_deploy_pack?)  { should be_false                    }
  end
  
  context "when BUNDLE_GEMFILE points at a deploy pack" do
    let(:dir)             { examples_dir('empty')       }
    let(:deploy_pack_dir) { examples_dir('deploy_pack') }
    before do
      FileUtils.cd(dir)
      ENV.stub!(:[]).with("BUNDLE_GEMFILE").and_return(deploy_pack_dir.join("Gemfile"))
    end
    subject   { runner.new }
    its(:deploy_pack_dir)  { should == deploy_pack_dir.to_s                               }
    its(:environment_file) { should == deploy_pack_dir.join("config/environment.rb").to_s }
    its(:in_deploy_pack?)  { should be_true                                               }
  end
  
  context "in an arbitrary Ruby project with a Gemfile" do
    let(:dir) { examples_dir('ruby_project') }
    before    { FileUtils.cd(dir)            }
    subject   { runner.new                   }
    its(:deploy_pack_dir)  { should == '/'                      }
    its(:environment_file) { should == '/config/environment.rb' }
    its(:in_deploy_pack?)  { should be_false                    }
  end

  context "in a deploy pack with a Gemfile and a config/environment.rb" do
    let(:dir) { examples_dir('deploy_pack')  }
    before    { FileUtils.cd(dir)            }
    subject   { runner.new                   }
    its(:deploy_pack_dir)  { should == dir.to_s                               }
    its(:environment_file) { should == dir.join('config/environment.rb').to_s }
    its(:in_deploy_pack?)  { should be_true                                   }
  end
  
end
