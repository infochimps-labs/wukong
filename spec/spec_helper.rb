require 'bundler' ; Bundler.setup(:default, :development, :test)

require 'wukong'
require 'wukong/spec_helpers'
require_relative './support/shared_examples_for_shortcuts'
require_relative './support/shared_examples_for_builders'
require_relative './support/integration_helper'
require_relative './support/shared_context_for_reducers'

RSpec.configure do |config|
  config.mock_with :rspec
  include Wukong::SpecHelpers
  include Wukong::Local::IntegrationHelper
end
