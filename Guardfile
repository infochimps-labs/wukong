# -*- ruby -*-

# More info at https://github.com/guard/guard#readme

# guard 'yard' do
#   watch(%r{lib/.+\.rb})
#   watch(%r{notes/.+\.(md|txt)}) { "notes" }
# end

rspec_opts = '--format progress'
# rspec_opts = '--format doc'

guard 'rspec', :version => 2, :cli => rspec_opts do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})       { |m| "spec/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')    { "spec" }
  watch(/spec\/support\/(.+)\.rb/){ "spec" }
end
