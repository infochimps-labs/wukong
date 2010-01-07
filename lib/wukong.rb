require 'wukong/boot'
require 'wukong/extensions'
require 'wukong/datatypes'
require 'wukong/logger'
require 'wukong/bad_record'
autoload :TypedStruct, 'wukong/typed_struct'
require 'configliere'
module Wukong
  autoload :Dfs,         'wukong/dfs'
  autoload :Script,      'wukong/script'
  autoload :Streamer,    'wukong/streamer'
end
