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
  watch(%r{^lib/(.+)\.rb$})            { |m| "spec/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')         { "spec" }
  watch(/spec\/support\/(.+)\.rb/)     { "spec" }
  watch(%r{^examples/(\w+)\.rb$})      { |m| "spec/examples/#{m[1]}_spec.rb" }
  watch(%r{^examples/(\w+)/(.+)\.rb$}) { |m| "spec/examples/#{m[1]}_spec.rb" }
end

# # This is an example with all options that you can specify for guard-process
# Dir['examples/**/*.rb'].each do |file|
#   next unless File.file?(file) && File.executable?(file)
#   guard 'process', :name => file, :command => file do
#     watch('Gemfile.lock')
#     watch(file)
#     watch('examples/examples_helper.rb')
#   end
# end

graph_output_dir = File.expand_path("/tmp/wukong-#{ENV['USER']}/graphs")
FileUtils.mkdir_p(graph_output_dir)

Dir['examples/**/*.gv'].each do |file|
  graph_output_file = File.join(graph_output_dir, File.basename(file, '.gv')+".png")
  cmd = "dot -Tpng -o #{graph_output_file} #{file}"
  guard 'process', :name => "dot on #{file}", :command => cmd do
    watch(file)
  end
end
