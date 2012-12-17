require 'wukong'
require 'wukong/spec_helpers'
require_relative './support/shared_examples_for_shortcuts'
require_relative './support/shared_examples_for_builders'
require_relative './support/shared_context_for_reducers'

RSpec.configure do |config|
  
  
  config.mock_with :rspec
  
  include Wukong::SpecHelpers
  def root
    @root ||= Pathname.new(File.join(File.dirname(__FILE__), '..'))
  end
  
  config.treat_symbols_as_metadata_keys_with_true_values = true
  
  config.before(:each) do
    ARGV.replace([])
    Wukong::Log.level = Log4r::OFF
  end
  
end
