# -*- ruby -*-

format = 'doc'          # 'doc' for more verbose, 'progress' for less
tags   = %w[  ]          # builder_spec model_spec

guard 'rspec', :version => 2, :cli => "--format #{format} #{ tags.map{|tag| "--tag #{tag}"}.join(' ')  }" do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^examples/(.+)\.rb$})       { |m| "spec/examples/#{m[1]}_spec.rb" }
  watch(%r{^lib/(.+)\.rb$})            { |m| "spec/#{m[1]}}_spec.rb"         }
  watch('spec/spec_helper.rb')         { 'spec' }
  watch(/spec\/support\/(.+)\.rb/)     { 'spec' }
end
