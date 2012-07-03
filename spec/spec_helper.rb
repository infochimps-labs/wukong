require 'bundler' ; Bundler.require(:default, :development, :test)

# SimpleCov.start do
#   add_filter '/gorillib/'
#   add_filter '/away/'
#   add_group  'Hanuman', '/hanuman/'
# end

require 'wukong'
require 'gorillib/pathname'

Pathname.register_path(:wukong_root, File.expand_path('..', File.dirname(__FILE__)))
Pathname.register_path(:examples,    :wukong_root, 'examples')
Pathname.register_path(:tmp,         :wukong_root, 'tmp')
Pathname.register_path(:data,        :wukong_root, 'data')
Pathname.path_to(:tmp).mkpath

Dir[ Pathname.path_to('spec', 'support', '*.rb') ].each{|f| require f }

result   = `dot -V 2>&1` rescue nil
GRAPHVIZ = ($?.exitstatus == 0) && (result =~ /dot - graphviz version/)
puts 'Some specs require graphviz to run -- brew/apt install graphviz, it is pretty awesome' unless GRAPHVIZ

RSpec.configure do |config|
  include WukongTestHelpers
  config.treat_symbols_as_metadata_keys_with_true_values = true
end
