require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:specs) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

require 'yard'
YARD::Rake::YardocTask.new

desc 'Run RSpec with code coverage'
task :cov do
  ENV['WUKONG_COV'] = "yep"
  Rake::Task[:specs].execute
end

task :default => :specs


