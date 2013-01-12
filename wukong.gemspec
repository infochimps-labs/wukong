# -*- encoding: utf-8 -*-
require File.expand_path('../lib/wukong/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = 'wukong'
  gem.homepage    = 'https://github.com/infochimps-labs/wukong'
  gem.licenses    = ["Apache 2.0"]
  gem.email       = 'coders@infochimps.com'
  gem.authors     = ['Infochimps', 'Philip (flip) Kromer', 'Travis Dempsey']
  gem.version     = Wukong::VERSION

  gem.summary     = 'Hadoop Streaming for Ruby. Wukong makes Hadoop so easy a chimpanzee can use it, yet handles terabyte-scale computation with ease.'
  gem.description = <<-EOF
  Treat your dataset like a:

      * stream of lines when it's efficient to process by lines
      * stream of field arrays when it's efficient to deal directly with fields
      * stream of lightweight objects when it's efficient to deal with objects

  Wukong is friends with Hadoop the elephant, Pig the query language, and the cat on your command line.
EOF

  gem.files         = `git ls-files`.split("\n").reject { |path| path =~ /^(data|docpages|notes|old)/ }
  gem.executables   = ['wu-local']
  gem.test_files    = gem.files.grep(/^spec/)
  gem.require_paths = ['lib']

  gem.add_dependency('configliere',             '>= 0.4.19')
  gem.add_dependency('multi_json',              '>= 1.3.6')
  gem.add_dependency('vayacondios-client',      '>= 0.1.2')
  gem.add_dependency('gorillib',                '>= 0.4.2')
  gem.add_dependency('forgery')
  gem.add_dependency('uuidtools')
  gem.add_dependency('eventmachine')
  gem.add_dependency('log4r')
end
