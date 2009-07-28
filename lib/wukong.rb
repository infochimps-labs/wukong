require 'wukong/boot'
require 'wukong/extensions'
require 'wukong/datatypes'
require 'wukong/logger'
autoload :TypedStruct, 'wukong/typed_struct'
module Wukong
  autoload :Dfs,         'wukong/dfs'
  autoload :Script,      'wukong/script'
  autoload :Streamer,    'wukong/streamer'
end
