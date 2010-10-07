Settings.define :cassandra_db_addrs, :description => ''
Settings.define :cassandra_db_port,  :description => ''

module Wukong
  module Store
    module CassandraStore
      autoload :StructLoader, 'wukong/store/cassandra/struct_loader'
    end
  end
end
