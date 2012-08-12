require 'rubygems' unless defined?(Gem)
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

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

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  Bundler.setup(:default, :development, :test)
  spec.pattern = FileList['spec/**/*_spec.rb']
end

require 'yard'
YARD::Rake::YardocTask.new do
  Bundler.setup(:default, :development, :docs)
end
