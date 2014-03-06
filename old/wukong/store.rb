module Wukong
  module Store
    autoload :Base,                    'wukong/store/base'
    autoload :FlatFileStore,           'wukong/store/flat_file_store'
    autoload :ChunkedFlatFileStore,    'wukong/store/chunked_flat_file_store'
    autoload :ChhChunkedFlatFileStore, 'wukong/store/chh_chunked_flat_file_store'

    autoload :CassandraModel,          'wukong/store/cassandra_model'
  end
end
