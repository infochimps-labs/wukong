require 'bundler/setup' ; Bundler.require(:development, :test)
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

YARD::Rake::YardocTask.new

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
  gem.add_development_dependency "rspec", ">= 1.2.9"
  gem.add_development_dependency "yard", ">= 0"
  gem.add_dependency 'addressable'
  gem.add_dependency 'extlib'
  gem.add_dependency 'htmlentities'
  gem.add_dependency 'configliere'
end

Jeweler::GemcutterTasks.new

task :default => :spec


