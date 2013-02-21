require          'configliere'
require          'multi_json'
require          'gorillib/pathname'
require          'gorillib/model/serialization'
require          'wukong/script'
require          'wukong/streamer/encoding_cleaner'
require_relative '../lib/wu/munging'

Pathname.register_paths(
  rawd: File.expand_path('../data', File.dirname(__FILE__))
)
