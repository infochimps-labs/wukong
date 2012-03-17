$LOAD_PATH.unshift(File.expand_path('../lib', File.dirname(__FILE__)))
require 'wukong'

Wukong.register_path(:wukong_root, File.expand_path('..', File.dirname(__FILE__)))
Wukong.register_path(:data,        [:wukong_root, 'data'])
Wukong.register_path(:output,      [:wukong_root, 'tmp'])
Wukong.register_path(:examples,    [:wukong_root, 'examples'])
