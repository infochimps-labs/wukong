require 'gorillib/pathname/template'
Gorillib.register_path(:wukong_root, File.expand_path('..', File.dirname(__FILE__)))
Gorillib.register_path(:examples,    [:wukong_root, 'examples'])

$LOAD_PATH.unshift(Gorillib.path_to('lib'))
$LOAD_PATH.unshift(Gorillib.path_to('spec', 'support'))

Dir[ Gorillib.path_to('spec', 'support', '*.rb') ].each{|f| require f }

RSpec.configure do |config|
  include WukongTestHelpers
end
