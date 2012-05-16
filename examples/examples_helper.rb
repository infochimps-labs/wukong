$LOAD_PATH.unshift(File.expand_path('../lib', File.dirname(__FILE__)))
require 'wukong'

Pathname.register_path(:wukong_root, File.expand_path('..', File.dirname(__FILE__)))
Pathname.register_path(:data,        [:wukong_root, 'data'])
Pathname.register_path(:output,      [:wukong_root, 'tmp'])
Pathname.register_path(:examples,    [:wukong_root, 'examples'])
