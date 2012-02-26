require 'log4r'
Log = Log4r::Logger.new('wukong')
Log.outputters = Log4r::Outputter.stderr

require 'configliere'
require 'gorillib'
require 'gorillib/string/inflections'
require 'gorillib/string/constantize'

require 'log_buddy'; LogBuddy.init :logger => Log

begin require 'yajl' ; require 'yajl/json_gem' ; rescue LoadError => e ; require 'json' end
require 'multi_json'

require 'wukong/flow'          # coordinates wukong stages
require 'wukong/stage'         # base object for building blocks
require 'wukong/streamer'      # processes records in series
require 'wukong/source'        # generates raw records from outside
require 'wukong/sink'          # dispatch raw records to outside

require 'wukong/formatter'     # converts raw blobs into structured records and vice/versa

# require 'wukong/map_reduce'    # the standard stream-sort-group-stream map/reduce flow
