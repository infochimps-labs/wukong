require 'rubygems'
require 'rake/gempackagetask'

CT_VERSION = '0.1'

GEM_SPEC = Gem::Specification.new do |spec|
  spec.platform = Gem::Platform.local
  spec.name = 'control_tower'
  spec.summary = "A Rack-based HTTP server for MacRuby"
  spec.description = <<-DESCRIPTION
  Control Tower is a Rack-based HTTP server designed to work with MacRuby. It can
  be used by calling to its Rack::Handler class, or by running the control_tower
  executable with a Rackup configuration file (see the control tower help for more
  details).
  DESCRIPTION
  spec.version = CT_VERSION
  spec.files = %w(
    lib/control_tower.rb
    lib/control_tower/rack_socket.rb
    lib/control_tower/server.rb
    lib/CTParser.bundle
    bin/control_tower
    lib/rack/handler/control_tower.rb
    lib/control_tower/vendor
    lib/control_tower/vendor/rack
    lib/control_tower/vendor/rack.rb
  ) + Dir.glob('lib/control_tower/vendor/rack/**/*')
  spec.executable = 'control_tower'
end

verbose(true)

desc "Same as all"
task :default => :all

desc "Build everything"
task :all => ['build', 'gem']

desc "Build CTParser"
task :build do
  gcc = RbConfig::CONFIG['CC']
  cflags = RbConfig::CONFIG['CFLAGS'] + ' ' + RbConfig::CONFIG['ARCH_FLAG']

  Dir.chdir('ext/CTParser') do
    sh "#{gcc} #{cflags} -fobjc-gc CTParser.m -c -o CTParser.o"
    sh "#{gcc} #{cflags} http11_parser.c -c -o http11_parser.o"
    sh "#{RbConfig::CONFIG['LDSHARED']} CTParser.o http11_parser.o -o CTParser.bundle"
  end
end

desc "Clean packages and extensions"
task :clean do
  sh "rm -rf pkg ext/CTParser/*.o ext/CTParser/*.bundle lib/*.bundle"
end

desc "Install as a standard library"
task :stdlib_install => [:build] do
  prefix = (ENV['DESTDIR'] || '')
  dest = File.join(prefix, RbConfig::CONFIG['sitelibdir'])
  mkdir_p(dest)
  sh "ditto lib \"#{dest}\""
  dest = File.join(prefix, RbConfig::CONFIG['sitearchdir'])
  mkdir_p(dest)
  sh "cp ext/CTParser/CTParser.bundle \"#{dest}\""
end

file 'ext/CTParser/CTParser.bundle' => 'build'

file 'lib/CTParser.bundle' => ['ext/CTParser/CTParser.bundle'] do
  FileUtils.cp('ext/CTParser/CTParser.bundle', 'lib/CTParser.bundle')
end

Rake::GemPackageTask.new(GEM_SPEC) do |pkg|
  pkg.need_zip = false
  pkg.need_tar = true
end

desc "Run Control Tower"
task :run do
  sh "macruby -I./lib -I./ext/CTParser bin/control_tower"
end
