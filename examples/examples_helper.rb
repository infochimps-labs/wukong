$LOAD_PATH.unshift(File.expand_path('../lib', File.dirname(__FILE__)))
require 'wukong'

Gorillib.register_path(:wukong_root, File.expand_path('..', File.dirname(__FILE__)))
Gorillib.register_path(:data,        [:wukong_root, 'data'])
Gorillib.register_path(:output,      [:wukong_root, 'tmp'])
Gorillib.register_path(:examples,    [:wukong_root, 'examples'])
