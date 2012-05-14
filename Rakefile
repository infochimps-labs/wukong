require 'rubygems'
require 'rake'

begin
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
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_development_dependency "yard", ">= 0"
    gem.add_dependency 'addressable'
    gem.add_dependency 'extlib'
    gem.add_dependency 'htmlentities'
    gem.add_dependency 'configliere'
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts 'Jeweler (or a dependency) not available. Install it with: gem install jeweler'
end

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec) do |spec|
    spec.pattern = 'spec/**/*_spec.rb'
  end
  RSpec::Core::RakeTask.new(:rcov) do |spec|
    spec.pattern = 'spec/**/*_spec.rb'
    spec.rcov    = true
  end
  task :default => :spec
rescue LoadError
  task :spec do
    abort 'rspec is not available. In order to run rspec, you must: sudo gem install rspec'
  end
end

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  task :yardoc do
    abort "YARD is not available. In order to run yardoc, you must: sudo gem install yard"
  end
end
