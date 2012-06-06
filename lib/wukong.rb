# require 'oj'
require 'multi_json'

require 'configliere'
require 'gorillib/logger/log'
require 'gorillib/some'
require 'gorillib/builder'
require 'gorillib/model/serialization'

require 'wukong/settings'

require 'hanuman'

#
# Dataflow specific
#
require 'wukong/universe'
require 'wukong/dataflow'

require 'wukong/processor'           # processes records in series
require 'wukong/widget/filter'       # passes through only records that meet `accept?`
require 'wukong/widget/source'       # generates raw records from outside
require 'wukong/widget/sink'         # dispatch raw records to outside
require 'wukong/widget/stringifier'  # converts raw blobs into structured records and vice/versa
require 'wukong/mapred'              # the standard stream-sort-group-stream map/reduce flow
require 'wukong/local_runner'
require 'wukong/bad_record'

#
# Workflow Specific
#
require 'wukong/workflow/command'
