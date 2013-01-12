require 'spec_helper'

describe 'wu-local' do

  let(:input) { %w[1 2 3] }
  
  context "without any arguments" do
    subject { wu_local() }
    it {should exit_with(:non_zero) }
    it "displays help on STDERR" do
      should have_stderr(/provide a processor.*to run/)
    end
  end

  context "running outside any Ruby project" do
    subject { wu_local('count').in(examples_dir('empty')) < input }
    it { should exit_with(0) }
    it "runs the processor" do
      should have_stdout("3")
    end
    context "when passed a BUNDLE_GEMFILE" do
      context "that doesn't belong to a deploy pack" do
        subject { wu_local('count').in(examples_dir('empty')).using(integration_env.merge("BUNDLE_GEMFILE" => examples_dir('ruby_project', 'Gemfile').to_s)) < input }
        it { should exit_with(0) }
        it "runs the processor" do
          should have_stdout("3")
        end
      end
      context "that belongs to a deploy pack" do
        subject { wu_local('count').in(examples_dir('empty')).using(integration_env.merge("BUNDLE_GEMFILE" => examples_dir('deploy_pack', 'Gemfile').to_s)) < input }
        it { should exit_with(0) }
        it "runs the processor" do
          should have_stdout("3")
        end
        context "loading the deploy pack" do
          subject { wu_local('string_reverser').in(examples_dir('empty')).using(integration_env.merge("BUNDLE_GEMFILE" => examples_dir('deploy_pack', 'Gemfile').to_s)) < 'hi' }
          it { should exit_with(0) }
          it "runs the processor" do
            should have_stdout("ih")
          end
        end
      end
    end
  end

  context "running within a Ruby project" do
    context "at its root" do
      subject { wu_local('count').in(examples_dir('ruby_project')) < input }
      it { should exit_with(0) }
      it "runs the processor" do
        should have_stdout("3")
      end
    end
    context "deep within it" do
      subject { wu_local('count').in(examples_dir('ruby_project')) < input }
      it { should exit_with(0) }
      it "runs the processor" do
        should have_stdout("3")
      end
    end
  end

  context "running within a deploy pack" do
    context "at its root" do
      subject { wu_local('count').in(examples_dir('deploy_pack')) < input }
      it { should exit_with(0) }
      it "runs the processor" do
        should have_stdout("3")
      end
      context "loading the deploy pack" do
        subject { wu_local('string_reverser').in(examples_dir('deploy_pack')) < 'hi' }
        it { should exit_with(0) }
        it "runs the processor" do
          should have_stdout("ih")
        end
      end
    end
    context "deep within it" do
      subject { wu_local('count').in(examples_dir('deploy_pack')) < input }
      it { should exit_with(0) }
      it "runs the processor" do
        should have_stdout("3")
      end
      context "loading the deploy pack" do
        subject { wu_local('string_reverser').in(examples_dir('deploy_pack')) < 'hi' }
        it { should exit_with(0) }
        it "runs the processor" do
          should have_stdout("ih")
        end
      end
    end
  end
end
