require 'spec_helper'

describe Wukong::Runner do

  context "can boot itself by" do

    describe "loading" do
      it "files passed on the command-line" do
        loadable = examples_dir('loadable.rb')
        generic_runner(loadable) do
          should_receive(:load_ruby_file).with(loadable)
        end
      end
      it "files when its in a deploy pack" do
        generic_runner { should_receive(:load_deploy_pack) }
      end
    end

    describe "configuring" do
      subject do
        Class.new(Wukong::Runner).tap do |configured|
          configured.class_eval do
            usage       'a nice usage message'
            description 'a lovely description'
          end
        end
      end
      
      it "a usage message" do
        runner(subject, 'wu-generic').settings.usage.should =~ /^usage: .* a nice usage message$/
      end

      it "a description" do
        runner(subject, 'wu-generic').settings.description.should == 'a lovely description'
      end

      it "plugins" do
        generic_runner { Wukong.should_receive(:configure_plugins) }
      end
    end

    describe "resolving" do
      it "doesn't move on if resolve causes an error" do
        generic_runner do
          settings.should_receive(:resolve!).and_raise(RuntimeError)
          should_not_receive(:setup)
          should_not_receive(:validate)
          should_not_receive(:run)
        end
      end
    end

    describe "setting up" do
      it "asks plugins to boot" do
        generic_runner do
          Wukong.should_receive(:boot_plugins)
        end
      end
    end

    describe "validating" do
      it "should run if validatation passes" do
        generic_runner do
          should_receive(:validate).and_return(true)
          should_receive(:run)
        end
      end
      it "dies if validate fails" do
        generic_runner do
          should_receive(:validate).and_return(false)
          should_not_receive(:run)
          should_receive(:die)
        end
      end
    end
  end

  context "situating itself within a deploy pack" do
    context "in an arbitrary directory" do
      let(:dir) { examples_dir('empty') }
      before    { FileUtils.cd(dir)     }
      subject   { generic_runner            }
      its(:deploy_pack_dir)  { should == '/'                      }
      its(:environment_file) { should == '/config/environment.rb' }
      its(:in_deploy_pack?)  { should be_false                    }
    end

    context "when BUNDLE_GEMFILE points at a regular Ruby project" do
      let(:dir)             { examples_dir('empty')       }
      let(:deploy_pack_dir) { examples_dir('ruby_project') }
      before do
        FileUtils.cd(dir)
        ENV.stub(:[]).with("BUNDLE_GEMFILE").and_return(File.join(deploy_pack_dir, 'Gemfile'))
      end
      subject   { generic_runner }
      its(:deploy_pack_dir)  { should == '/'                      }
      its(:environment_file) { should == '/config/environment.rb' }
      its(:in_deploy_pack?)  { should be_false                    }
    end
    
    context "when BUNDLE_GEMFILE points at a deploy pack" do
      let(:dir)             { examples_dir('empty')       }
      let(:deploy_pack_dir) { examples_dir('deploy_pack') }
      before do
        FileUtils.cd(dir)
        ENV.stub(:[]).with("BUNDLE_GEMFILE").and_return(File.join(deploy_pack_dir, 'Gemfile'))
      end
      subject   { generic_runner }
      its(:deploy_pack_dir)  { should == deploy_pack_dir.to_s                               }
      its(:environment_file) { should == File.join(deploy_pack_dir, 'config/environment.rb')}
      its(:in_deploy_pack?)  { should be_true                                               }
    end
    
    context "in an arbitrary Ruby project with a Gemfile" do
      let(:dir) { examples_dir('ruby_project') }
      before    { FileUtils.cd(dir)            }
      subject   { generic_runner                   }
      its(:deploy_pack_dir)  { should == '/'                      }
      its(:environment_file) { should == '/config/environment.rb' }
      its(:in_deploy_pack?)  { should be_false                    }
    end

    context "in a deploy pack with a Gemfile and a config/environment.rb" do
      let(:dir) { examples_dir('deploy_pack')  }
      before    { FileUtils.cd(dir)            }
      subject   { generic_runner                       }
      its(:deploy_pack_dir)  { should == dir                                    }
      its(:environment_file) { should == File.join(dir, 'config/environment.rb')}
      its(:in_deploy_pack?)  { should be_true                                   }
    end
  end
end
