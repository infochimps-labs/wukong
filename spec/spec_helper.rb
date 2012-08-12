if ENV['WUKONG_COV']
  require 'simplecov'
  SimpleCov.start do
    add_filter '/gorillib/'
    add_filter '/away/'
    add_group  'Hanuman', '/hanuman/'
  end
end

require 'wukong'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
end
