module Monkeyshines
  module Store
    extend FactoryModule
    autoload :Base,                 'monkeyshines/store/base'
    autoload :FlatFileStore,        'monkeyshines/store/flat_file_store'
    autoload :ConditionalStore,     'monkeyshines/store/conditional_store'
    autoload :ChunkedFlatFileStore, 'monkeyshines/store/chunked_flat_file_store'
    autoload :KeyStore,             'monkeyshines/store/key_store'
    autoload :TokyoTdbKeyStore,     'monkeyshines/store/tokyo_tdb_key_store'
    autoload :TyrantTdbKeyStore,    'monkeyshines/store/tyrant_tdb_key_store'
    autoload :TyrantRdbKeyStore,    'monkeyshines/store/tyrant_rdb_key_store'
    autoload :ReadThruStore,        'monkeyshines/store/read_thru_store'
  end
end
