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

# This is an example with all options that you can specify for guard-process
Dir['examples/**/*.rb'].each do |file|
  next unless File.file?(file) && File.executable?(file)
  guard 'process', :name => file, :command => file do
    watch('Gemfile.lock')
    watch(file)
    watch('examples/examples_helper.rb')
  end
end
