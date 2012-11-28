require 'bundler' ; Bundler.setup(:default, :development, :test)

if ENV['WUKONG_COV']
  require 'simplecov'

  SimpleCov.start do
    add_filter '/gorillib/'
    add_filter '/away/'
    add_group  'Hanuman', '/hanuman/'
  end
end

require 'wukong'
require 'wukong/spec_helpers'
require_relative './support/shared_examples_for_builders'
require_relative './support/shared_examples_for_shortcuts'
require_relative './support/shared_context_for_reducers'

# require 'gorillib/pathname'
# require 'gorillib/type/extended'
# require 'wukong/model/faker'

# Pathname.register_path(:wukong_root, File.expand_path('..', File.dirname(__FILE__)))
# Pathname.register_path(:examples,    :wukong_root, 'examples')
# Pathname.register_path(:tmp,         :wukong_root, 'tmp')
# Pathname.register_path(:data,        :wukong_root, 'data')
# Pathname.path_to(:tmp).mkpath

# Dir[ Pathname.path_to('spec', 'support', '*.rb') ].each{|f| require f }

# result   = `dot -V 2>&1` rescue nil
# GRAPHVIZ = ($?.exitstatus == 0) && (result =~ /dot - graphviz version/)
# puts 'Some specs require graphviz to run -- brew/apt install graphviz, it is pretty awesome' unless GRAPHVIZ

RSpec.configure do |config|
  config.mock_with :rspec
  include Wukong::SpecHelpers
  # config.treat_symbols_as_metadata_keys_with_true_values = true
end
