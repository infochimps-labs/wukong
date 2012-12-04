require 'spec_helper'

describe 'wu-local' do

  let(:input) { %w[1 2 3] }
  
  context "without any arguments" do
    subject { command('wu-local') }
    it {should exit_with(:non_zero) }
    it "displays help on STDERR" do
      should have_stderr("usage: wu-local")
    end
  end

  context "running outside any Ruby project" do
    subject { command('wu-local count').in(examples_dir('empty')) < input }
    it { should exit_with(0) }
    it "runs the processor" do
      should have_stdout("3")
    end
    context "when passed a BUNDLE_GEMFILE" do
      context "that doesn't belong to a deploy pack" do
        subject { command('wu-local count').in(examples_dir('empty')).using(integration_env.merge("BUNDLE_GEMFILE" => examples_dir('ruby_project', 'Gemfile').to_s)) < input }
        it { should exit_with(0) }
        it "runs the processor" do
          should have_stdout("3")
        end
      end
      context "that belongs to a deploy pack" do
        subject { command('wu-local count').in(examples_dir('empty')).using(integration_env.merge("BUNDLE_GEMFILE" => examples_dir('deploy_pack', 'Gemfile').to_s)) < input }
        it { should exit_with(0) }
        it "runs the processor" do
          should have_stdout("3")
        end
        context "loading the deploy pack" do
          subject { command('wu-local string_reverser').in(examples_dir('empty')).using(integration_env.merge("BUNDLE_GEMFILE" => examples_dir('deploy_pack', 'Gemfile').to_s)) < 'hi' }
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
      subject { command('wu-local count').in(examples_dir('ruby_project')) < input }
      it { should exit_with(0) }
      it "runs the processor" do
        should have_stdout("3")
      end
    end
    context "deep within it" do
      subject { command('wu-local count').in(examples_dir('ruby_project')) < input }
      it { should exit_with(0) }
      it "runs the processor" do
        should have_stdout("3")
      end
    end
  end

  context "running within a deploy pack" do
    context "at its root" do
      subject { command('wu-local count').in(examples_dir('deploy_pack')) < input }
      it { should exit_with(0) }
      it "runs the processor" do
        should have_stdout("3")
      end
      context "loading the deploy pack" do
        subject { command('wu-local string_reverser').in(examples_dir('deploy_pack')) < 'hi' }
        it { should exit_with(0) }
        it "runs the processor" do
          should have_stdout("ih")
        end
      end
    end
    context "deep within it" do
      subject { command('wu-local count').in(examples_dir('deploy_pack')) < input }
      it { should exit_with(0) }
      it "runs the processor" do
        should have_stdout("3")
      end
      context "loading the deploy pack" do
        subject { command('wu-local string_reverser').in(examples_dir('deploy_pack')) < 'hi' }
        it { should exit_with(0) }
        it "runs the processor" do
          should have_stdout("ih")
        end
      end
    end
  end
  
  # context "running within a deploy pack" do
  #   context "at its root" do
  #     let(:subject) { command('wu-local', :cwd => examples_dir('deploy_pack')) }
  #   end
  #   context "deep within it" do
  #     let(:subject) { command('wu-local', :cwd => examples_dir('deploy_pack', 'a','b','c')) }
  #   end
  # end
  
  # context "in local mode" do
  #   context "on a map-only job" do
  #     let(:subject) { command('wu-hadoop', example_script('tokenizer.rb'), "--mode=local", "--input=#{example_script('sonnet_18.txt')}") }
  #     it { should exit_with(0) }
  #     it { should have_stdout('Shall', 'I', 'compare', 'thee', 'to', 'a', "summer's", 'day') }
  #   end
    
  #   context "on a map-reduce job" do
  #     let(:subject) { command('wu-hadoop', example_script('word_count.rb'), "--mode=local", "--input=#{example_script('sonnet_18.txt')}") }
  #     it { should exit_with(0) }
  #     it { should have_stdout(/complexion\s+1/, /Death\s+1/, /temperate\s+1/) }
  #   end
  # end

  # context "in Hadoop mode" do
  #   context "on a map-only job" do
  #     let(:subject) { command('wu-hadoop', example_script('tokenizer.rb'), "--mode=hadoop", "--input=/data/in", "--output=/data/out", "--dry_run") }
  #     it { should exit_with(0) }
  #     it { should have_stdout(%r{jar.*hadoop.*streaming.*\.jar}, %r{-mapper.+tokenizer\.rb}, %r{-input.*/data/in}, %r{-output.*/data/out}) }
  #   end
  # end
  
end
