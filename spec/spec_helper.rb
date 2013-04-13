require 'wukong'
require 'wukong/spec_helpers'
require_relative './support/shared_context_for_graphs'
require_relative './support/shared_examples_for_shortcuts'
require_relative './support/shared_examples_for_builders'
require_relative './support/shared_context_for_reducers'

RSpec.configure do |config|
  
  config.mock_with :rspec
  
  include Wukong::SpecHelpers
  def root
    @root ||= Pathname.new(File.expand_path('../..', __FILE__))
  end

  def local_runner *args
    runner(Wukong::Local::LocalRunner, 'wu-local', *args)
  end

  def generic_runner *args
    runner(Wukong::Runner, 'wu-generic', *args)
  end

  def wu_local *args
    command('wu-local', *args)
  end
  
  # FIXME Why is this here?
  config.treat_symbols_as_metadata_keys_with_true_values = true
  
end
