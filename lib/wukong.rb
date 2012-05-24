unless defined?(Log)
  require 'log4r'
  Log = Log4r::Logger.new('wukong')
  Log.outputters = Log4r::Outputter.stderr
  # require 'logger'
  # Log = Logger.new(STDERR)
end

# require 'log_buddy'; LogBuddy.init :log_to_stdout => false, :logger => Log
# LogBuddy::Utils.module_eval do
#   def arg_and_blk_debug(arg, blk)
#     result = eval(arg, blk.binding)
#     result_str = obj_to_string(result, :quote_strings => true)
#     LogBuddy.debug(%[#{arg} = #{result_str}])
#   end
# end

begin require 'yajl' ; require 'yajl/json_gem' ; rescue LoadError => e ; require 'json' end
require 'multi_json'

require 'configliere'
require 'gorillib/some'

require 'gorillib/builder'

# require 'wukong/mixin/from_file'
# require 'wukong/registry'
# require 'wukong/path_helpers'

require 'wukong/settings'

require 'hanuman'

# Dataflow

require 'wukong/universe'
require 'wukong/dataflow'
require 'wukong/workflow'

require 'wukong/processor'           # processes records in series
require 'wukong/widget/filter'       # passes through only records that meet `accept?`
require 'wukong/widget/source'       # generates raw records from outside
require 'wukong/widget/sink'         # dispatch raw records to outside
require 'wukong/widget/stringifier'  # converts raw blobs into structured records and vice/versa
require 'wukong/mapred'              # the standard stream-sort-group-stream map/reduce flow

require 'wukong/local_runner'
require 'wukong/workflow/command'
