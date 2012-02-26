# -*- ruby -*-

# More info at https://github.com/guard/guard#readme

# guard 'yard' do
#   watch(%r{lib/.+\.rb})
#   watch(%r{notes/.+\.(md|txt)}) { "notes" }
# end

guard 'rspec', :version => 2, :cli => '--format doc' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})       { |m| "spec/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')    { "spec" }
  watch(/spec\/support\/(.+)\.rb/){ "spec" }
end
