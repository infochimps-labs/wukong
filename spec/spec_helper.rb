require 'wukong/path_helpers'
Wukong.register_path(:wukong_root, File.expand_path('..', File.dirname(__FILE__)))
Wukong.register_path(:examples,    [:wukong_root, 'examples'])

$LOAD_PATH.unshift(Wukong.path_to('lib'))
$LOAD_PATH.unshift(Wukong.path_to('spec', 'support'))

Dir[ Wukong.path_to('spec', 'support', '*.rb') ].each{|f| require f }

RSpec.configure do |config|
  include WukongTestHelpers
end
