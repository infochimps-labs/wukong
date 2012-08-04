# -*- encoding: utf-8 -*-
require File.expand_path('../lib/wukong/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = 'wukong'
  gem.version       = Wukong::VERSION
  gem.authors       = ['Philip (flip) Kromer', 'Travis Dempsey']
  gem.homepage      = 'https://github.com/infochimps-labs/wukong'
  gem.summary       = 'Hadoop Streaming for Ruby. Wukong makes Hadoop so easy a chimpanzee can use it, yet handles terabyte-scale computation with ease.'
  gem.description   = <<DESC
  Treat your dataset like a:

      * stream of lines when it's efficient to process by lines
      * stream of field arrays when it's efficient to deal directly with fields
      * stream of lightweight objects when it's efficient to deal with objects

  Wukong is friends with Hadoop the elephant, Pig the query language, and the cat on your command line.
DESC

  gem.files         = `git ls-files`.split("\n")
  gem.executables   = [] # gem.files.grep(/^bin/).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(/^spec/)
  gem.require_paths = ['lib']

  gem.add_dependency             'oj',          "~> 1.2"
  gem.add_dependency             'multi_json',  ">= 1.3"

  gem.add_dependency             'gorillib',    "~> 0.4.0"
  gem.add_dependency             'configliere', "~> 0.4.8"

  gem.add_dependency             'algorithms',  "~> 0.5"

  gem.add_development_dependency 'bundler',     "~> 1.1"
  gem.add_development_dependency 'rake',        ">= 0.9"

  gem.add_development_dependency 'forgery'
  gem.add_development_dependency 'uuidtools'
  gem.add_development_dependency 'addressable'
  gem.add_development_dependency 'home_run'

end
