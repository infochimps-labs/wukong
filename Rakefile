require 'rubygems' unless defined?(Gem)
require 'bundler/setup'
Bundler.setup(:default, :development)
require 'rake'

task :default => :rspec

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:rspec) do |spec|
  Bundler.setup(:default, :development, :test)
  spec.pattern = FileList['spec/**/*_spec.rb']
end

desc "Run RSpec with code coverage"
task :cov do
  ENV['WUKONG_COV'] = "yep"
  Rake::Task["spec"].execute
end

require 'yard'
YARD::Rake::YardocTask.new do
  Bundler.setup(:default, :development, :docs)
end

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name        = "wukong"
  gem.authors     = ["Philip (flip) Kromer"]
  gem.email       = "flip@infochimps.org"
  gem.homepage    = "http://mrflip.github.com/wukong"
  gem.summary     = %Q{Hadoop Streaming for Ruby. Wukong makes Hadoop so easy a chimpanzee can use it, yet handles terabyte-scale computation with ease.}
  gem.description = <<DESC
  Treat your dataset like a:

      * stream of lines when it's efficient to process by lines
      * stream of field arrays when it's efficient to deal directly with fields
      * stream of lightweight objects when it's efficient to deal with objects

  Wukong is friends with Hadoop the elephant, Pig the query language, and the cat on your command line.
DESC
  gem.executables = FileList[* %w[bin/hdp-du bin/hdp-sync bin/hdp-wc bin/wu-lign bin/wu-sum bin/*.rb]].pathmap('%f')
  gem.files       =  FileList["\w*", "**/*.textile", "{bin,docpages,examples,lib,spec,utils}/**/*"]
end
Jeweler::RubygemsDotOrgTasks.new
