code_root =
$LOAD_PATH.unshift(File.expand_path('../lib', File.dirname(__FILE__)))
require 'wukong'

Wukong.register_path(:code_root,   File.expand_path('..', File.dirname(__FILE__)))
Wukong.register_path(:data_dir,    [:code_root, 'data'])
Wukong.register_path(:output_dir,  [:code_root, 'tmp'])
