require 'rubygems' unless defined?(Gem)
require 'bundler/setup'
Bundler.setup(:default, :development)
require 'rake'

task :default => :rspec

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:rspec) do |spec|
  Bundler.setup(:default, :development, :test)
  spec.pattern = 'spec/**/*_spec.rb'
end

desc "Run RSpec with code coverage"
task :cov do
  ENV['WUKONG_COV'] = "yep"
  Rake::Task[:rspec].execute
end

require 'yard'
YARD::Rake::YardocTask.new do
  Bundler.setup(:default, :development, :docs)
end

Bundler::GemHelper.install_tasks
