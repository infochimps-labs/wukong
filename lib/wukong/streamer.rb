module Wukong
  module Streamer
    autoload :Base,                    'wukong/streamer/base'
    autoload :LineStreamer,            'wukong/streamer/line_streamer'
    autoload :RecordStreamer,          'wukong/streamer/record_streamer'
    autoload :JsonStreamer,            'wukong/streamer/json_streamer'
    autoload :StructStreamer,          'wukong/streamer/struct_streamer'
    autoload :StructRecordizer,        'wukong/streamer/struct_streamer'
    autoload :InstanceStreamer,        'wukong/streamer/instance_streamer'
    #
    autoload :Filter,                  'wukong/streamer/filter'
    #
    autoload :Reducer,                 'wukong/streamer/reducer'
    autoload :AccumulatingReducer,     'wukong/streamer/accumulating_reducer'
    autoload :CountingReducer,         'wukong/streamer/counting_reducer'
    autoload :ListReducer,             'wukong/streamer/list_reducer'
    autoload :RankAndBinReducer,       'wukong/streamer/rank_and_bin_reducer'
    autoload :UniqByLastReducer,       'wukong/streamer/uniq_by_last_reducer'

    class Streamer < Base
    end

    class IdentityMapper < Base
    end

    class IdentityReducer < Base
    end

  end
end
