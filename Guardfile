# -*- ruby -*-

format = 'progress' # 'doc' for more verbose, 'progress' for less
tags   = %w[ ]      # builder_spec model_spec

guard 'rspec', :version => 2, :cli => "--format #{format} #{ tags.map{|tag| "--tag #{tag}"}.join(' ')  }" do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^examples/(\w+)/(.+)\.rb$}) { |m| "spec/examples/#{m[1]}_spec.rb" }
  watch(%r{^examples/(\w+)\.rb$})      { |m| "spec/examples/#{m[1]}_spec.rb" }
  watch(%r{^lib/(.+)/(.+)\.rb$})       { |m| "spec/#{m[1]}/#{m[2]}_spec.rb"  }
  watch(%r{^lib/(\w+)\.rb$})           { |m| "spec/#{m[1]}}_spec.rb"         }
  watch('spec/spec_helper.rb')         { 'spec' }
  watch(/spec\/support\/(.+)\.rb/)     { 'spec' }
end
