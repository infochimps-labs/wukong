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

RSpec.configure do |config|
  config.mock_with :rspec
  include Wukong::SpecHelpers
end
