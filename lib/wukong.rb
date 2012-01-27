require 'wukong/extensions'
require 'configliere'; Settings.use :define
require 'wukong/datatypes'
require 'wukong/periodic_monitor'
require 'wukong/logger'
autoload :BadRecord,   'wukong/bad_record'
autoload :TypedStruct, 'wukong/typed_struct'
module Wukong
  autoload :Script,          'wukong/script'
  autoload :Streamer,        'wukong/streamer'
  autoload :Store,           'wukong/store'
  autoload :FilenamePattern, 'wukong/filename_pattern'
  autoload :Decorator,       'wukong/decorator'

  def self.run mapper, reducer=nil, options={}
    Wukong::Script.new(mapper, reducer, options).run
  end
end
