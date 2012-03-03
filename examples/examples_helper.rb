code_root = File.expand_path('..', File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(code_root, 'lib'))
require 'wukong'

Wukong.register_path(:code_root,    code_root)
Wukong.register_path(:example_data, [:code_root, 'data'])

p [$LOAD_PATH, Wukong.path_to(:example_data, 'jabberwocky.txt')]
