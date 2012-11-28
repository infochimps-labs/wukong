require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:specs)

require 'yard'
YARD::Rake::YardocTask.new

desc 'Run RSpec with code coverage'
task :cov do
  ENV['WUKONG_COV'] = true
  Rake::Task[:specs].execute
end

task :default => :specs

desc "Create a TAGS file for this project"
task :tags do
  files = [%w[Gemfile Guardfile Rakefile README.md].map { |b| File.join(File.dirname(__FILE__), b) }]
  %w[bin examples lib spec].each do |dir|
    files << Dir[File.join(File.dirname(__FILE__), "#{dir}/**/*.rb")]
  end
  files.each do |arry|
    sh "etags", *arry unless arry.empty?
  end
end

