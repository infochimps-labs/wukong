Bundler::GemHelper.install_tasks
require 'rspec/core/rake_task'
require 'yard'

RSpec::Core::RakeTask.new(:rspec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

YARD::Rake::YardocTask.new

task :default => :rspec


