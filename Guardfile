# -*- ruby -*-

# More info at https://github.com/guard/guard#readme

# guard 'yard' do
#   watch(%r{lib/.+\.rb})
#   watch(%r{notes/.+\.(md|txt)}) { "notes" }
# end

# '--format doc'     for more verbose, --format progress for less
format  = "progress"
# '--tag record_spec' to only run tests tagged :record_spec
tags    = %w[ ]  # builder_spec model_spec

guard 'rspec', :version => 2, :cli => "--format #{format} #{ tags.map{|tag| "--tag #{tag}"}.join(" ")  }" do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^examples/(\w+)/(.+)\.rb$}) { |m| "spec/examples/#{m[1]}_spec.rb" }
  watch(%r{^examples/(\w+)\.rb$})      { |m| "spec/examples/#{m[1]}_spec.rb" }
  watch(%r{^lib/(.+)/(.+)\.rb$})       { |m| "spec/#{m[1]}/#{m[2]}_spec.rb" }
  watch(%r{^lib/(\w+)\.rb$})           { |m| "spec/#{m[1]}}_spec.rb" }
  watch('spec/spec_helper.rb')         { "spec" }
  watch(/spec\/support\/(.+)\.rb/)     { "spec" }
end

# graph_output_dir = File.expand_path("/tmp/wukong-#{ENV['USER']}/graphs")
# FileUtils.mkdir_p(graph_output_dir)
# Dir['examples/**/*.gv'].each do |file|
#   graph_output_file = File.join(graph_output_dir, File.basename(file, '.gv')+".png")
#   cmd = "dot -Tpng -o #{graph_output_file} #{file}"
#   guard 'process', :name => "dot on #{file}", :command => cmd do
#     watch(file)
#   end
# end
