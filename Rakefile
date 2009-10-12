# -*- coding: utf-8 -*-
require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
    gem.name        = "wukong"
    gem.executables = FileList['bin/*'].pathmap('%f')
    gem.files       =  FileList["\w*", "{config,doc,examples,spec,lib}/**/*"].reject{|file| file.to_s =~ %r{config/private\.yaml} }
    gem.summary     = "Wukong makes Hadoop so easy a chimpanzee can use it."
    gem.email       = "flip@infochimps.org"
    gem.homepage    = "http://mrflip.github.com/wukong"
    gem.authors     = ["Philip (flip) Kromer"]
    gem.email       = "flip@infochimps.org"
    gem.add_dependency 'addressable'
    gem.add_dependency 'extlib'
    gem.add_dependency 'htmlentities'
    gem.description = <<DESC
  Treat your dataset like a:

      * stream of lines when it’s efficient to process by lines
      * stream of field arrays when it’s efficient to deal directly with fields
      * stream of lightweight objects when it’s efficient to deal with objects

  Wukong is friends with Hadoop the elephant, Pig the query language, and the cat on your command line.
DESC
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end
task :spec => :check_dependencies
task :default => :spec

begin
  require 'reek/rake_task'
  Reek::RakeTask.new do |t|
    t.fail_on_error = true
    t.verbose = false
    t.source_files = ['lib/**/*.rb', 'examples/**/*.rb']
  end
rescue LoadError
  task :reek do
    abort "Reek is not available. In order to run reek, you must: sudo gem install reek"
  end
end

begin
  require 'roodi'
  require 'roodi_task'
  RoodiTask.new do |t|
    t.verbose = false
  end
rescue LoadError
  task :roodi do
    abort "Roodi is not available. In order to run roodi, you must: sudo gem install roodi"
  end
end

begin
  require 'yard'
  YARD::Rake::YardocTask.new do |yard|
  end
rescue LoadError
  task :yardoc do
    abort "YARD is not available. In order to run yardoc, you must: sudo gem install yard"
  end
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  require 'rdoc'
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.options += [
    '-SHN',
    '-f', 'darkfish',  # use darkfish rdoc styler
  ]
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "edamame #{version}"
  #
  File.open(File.dirname(__FILE__)+'/.document').each{|line| rdoc.rdoc_files.include(line.chomp) }
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION.yml')
    config = YAML.load(File.read('VERSION.yml'))
    version = "#{config[:major]}.#{config[:minor]}.#{config[:patch]}"
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "monkeyshines #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

