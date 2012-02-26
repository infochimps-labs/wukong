CODE_ROOT = File.expand_path("..", File.dirname(__FILE__)) unless defined?(CODE_ROOT)
def CODE_ROOT(*path_segs) File.expand_path(File.join(*path_segs), CODE_ROOT) ; end

$LOAD_PATH.unshift(CODE_ROOT('lib'))
$LOAD_PATH.unshift(CODE_ROOT('spec', 'support'))

Dir[CODE_ROOT('spec', 'support', '*.rb')].each{|f| require f }

RSpec.configure do |config|
  include WukongTestHelpers
end
